//
//  SPInterstitialClient.m
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <objc/runtime.h>
#import "SPInterstitialClient.h"
#import "SPTPNManager.h"
#import "SPInterstitialClient_SDKPrivate.h"
#import "SPInterstitialResponse.h"
#import "SPInterstitialOffer.h"
#import "SPURLGenerator.h"
#import "SPRandomID.h"
#import "SPLogger.h"
#import "SPInterstitialEventHub.h"
#import "SPInterstitialEvent.h"
#import "SPConstants.h"
#import "NSURL+SPDescription.h"
#import "SPCredentials.h"
#import "SPVersionChecker.h"
#import "NSURLRequest+UserAgent.h"

/* Error related constants */
NSString *const SPInterstitialClientErrorDomain = @"SPInterstitialClientErrorDomain";
const NSInteger SPInterstitialClientCannotInstantiateAdapterErrorCode = -8;
const NSInteger SPInterstitialClientInvalidStateErrorCode = -9;
const NSInteger SPInterstitialClientConnectionErrorCode = -10;
NSString *const SPInterstitialClientErrorLoggableDescriptionKey = @"SPInterstitialClientErrorLoggableDescriptionKey";

/* Offer data dictionary keys, accessed only within the implementation of this class */
static NSString *const SPInterstitialClientOfferDataRequestIdKey = @"SPInterstitialClientOfferDataRequestIdKey";
static NSString *const SPInterstitialClientOfferDataAdIdKey = @"SPInterstitialClientAdIdKey";

typedef NS_ENUM(NSInteger, SPInterstitialClientState) {
    SPInterstitialClientReadyToCheckOffersState,
    SPInterstitialClientRequestingOffersState,
    SPInterstitialClientValidatingOffersState,
    SPInterstitialClientReadyToShowInterstitialState,
    SPInterstitialClientShowingInterstitialState
};

BOOL SPInterstitialClientState_canCheckOffers(SPInterstitialClientState state)
{
    return state == SPInterstitialClientReadyToCheckOffersState || state == SPInterstitialClientReadyToShowInterstitialState;
}

@interface SPInterstitialClient ()

@property (nonatomic, strong) SPCredentials *credentials;
@property (nonatomic, strong) NSString *lastRequestID;
@property (nonatomic, strong) SPInterstitialEventHub *eventHub;
@property (nonatomic, strong) SPInterstitialOffer *selectedOffer;
@property (nonatomic, strong) void (^updateCredentials)();
@property (nonatomic, strong, readonly) NSMutableDictionary *adapters;

@property (nonatomic, assign) SPInterstitialClientState state;

@end

@implementation SPInterstitialClient {
    NSMutableDictionary *_adapters;
    SPURLGenerator *_URLGenerator;
}

/** Singleton because the SDKs wrapped in the underlying adapters might not support
 being instantiated multiple times **/
+ (instancetype)sharedClient
{
    static SPInterstitialClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _sharedClient = [[self alloc] init]; });

    return _sharedClient;
}

- (id)init
{
    self = [super init];

    if (self) {
        self.state = SPInterstitialClientReadyToCheckOffersState;
        self.eventHub = [[SPInterstitialEventHub alloc] init];
    }

    return self;
}


- (void)setCredentials:(SPCredentials *)credentials
{
    // We cannot change credentials until the next request is performed
    // If the user changes the credentials after requesting an interstitials
    // all the events should be tracked with the old credentials.
    if (self.state != SPInterstitialClientReadyToCheckOffersState) {
        __typeof(self) __weak weakSelf = self;
        SPLogDebug(@"Scheduling change of interstitials credentials to %@", credentials);

        // Creates the block that will update the credentials
        self.updateCredentials = ^{
        SPLogDebug(@"Executing change of interstitials credentials to %@", credentials);
        __typeof(weakSelf) __strong strongSelf = weakSelf;

        if (!strongSelf) {
            return;
        }

        strongSelf->_credentials = credentials;
        strongSelf->_eventHub.credentials = credentials;
        strongSelf->_URLGenerator = nil;
        };
    } else {
        SPLogDebug(@"Changing interstitials credentials to %@", credentials);
        self->_credentials = credentials;
        self->_eventHub.credentials = credentials;
        self->_URLGenerator = nil;
        self.updateCredentials = nil;
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"appId"];
    [self removeObserver:self forKeyPath:@"userId"];
}


#pragma mark - Adapter configuration

- (id<SPInterstitialNetworkAdapter>)adapterForNetworkName:(NSString *)networkName
{
    return [SPTPNManager getInterstitialAdapterForNetwork:networkName];
}


#pragma mark - Checking for available interstitial
- (void)checkInterstitialAvailable
{
    if (SPFoundationVersionNumber < NSFoundationVersionNumber_iOS_5_0) {
        SPLogError(@"The device is running a version of iOS (%f) that is inferior to the lowest iOS version (%f) "
                   @"compatible with Fyber's SDK",
                   SPFoundationVersionNumber,
                   NSFoundationVersionNumber_iOS_5_0);
        SPLogInfo(@"No offers will be returned");

        [self performSelector:@selector(callDelegateWithNoOffers) withObject:nil afterDelay:0.0];

        return;
    }


    if (!SPInterstitialClientState_canCheckOffers(self.state)) {
        NSString *errorDescriptionFormat = @"%s cannot check for available interstitials at this point.";

        [self failWithInvalidStateErrorWithDescription:[NSString stringWithFormat:errorDescriptionFormat, __PRETTY_FUNCTION__]];
        return;
    }

    if (self.updateCredentials) {
        self.updateCredentials();
        self.updateCredentials = nil;
    }

    self.selectedOffer = nil;
    self.state = SPInterstitialClientRequestingOffersState;

    void (^requestCompletionHandler)(NSURLResponse *, NSData *, NSError *) =
    ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    SPInterstitialResponse *interstitialResponse =
    [SPInterstitialResponse responseWithURLResponse:response data:data connectionError:connectionError];

    if (!interstitialResponse.isSuccessResponse) {
        self.state = SPInterstitialClientReadyToCheckOffersState;
        [self failWithErrorDescription:@"An error occurred while requesting interstitial offers"
                       underlyingError:interstitialResponse.error];
        return;
    }

    self.state = SPInterstitialClientValidatingOffersState;
    SPInterstitialOffer *selectedOffer = [self offerSelectedFromResponse:interstitialResponse];

    BOOL canShowInterstitial;
    SPInterstitialClientState newState;

    if (selectedOffer) {
        canShowInterstitial = YES;
        newState = SPInterstitialClientReadyToShowInterstitialState;
        [self fireNotification:SPInterstitialEventTypeFill offer:nil];
    } else {
        canShowInterstitial = NO;
        newState = SPInterstitialClientReadyToCheckOffersState;
        [self fireNotification:SPInterstitialEventTypeNoFill offer:nil];
    }

    self.selectedOffer = selectedOffer;
    self.state = newState;
    [self.delegate interstitialClient:self canShowInterstitial:canShowInterstitial];
    };

    // Set the right Use-Agent

    NSURLRequest *requestForOffers = [self URLRequestForOffers];

    SPLogDebug(@"Requesting interstitial offers: %@", [requestForOffers.URL SPPrettyDescription]);
    [NSURLConnection sendAsynchronousRequest:requestForOffers
                                       queue:[self queueForRequestCallback]
                           completionHandler:requestCompletionHandler];
}

- (NSURLRequest *)URLRequestForOffers
{
    SPURLGenerator *urlGenerator = [SPURLGenerator URLGeneratorWithEndpoint:SPURLEndpointInterstitial];

    [urlGenerator setCredentials:self.credentials];
    NSString *requestID = [SPRandomID randomIDString];
    [urlGenerator setParameterWithKey:SPUrlGeneratorRequestIDKey stringValue:requestID];
    self.lastRequestID = requestID;

    return [NSURLRequest requestSPUserAgentAndURL:[urlGenerator generatedURL]];
}

- (NSOperationQueue *)queueForRequestCallback
{
    return [NSOperationQueue mainQueue];
}

- (SPInterstitialOffer *)offerSelectedFromResponse:(SPInterstitialResponse *)response
{
    for (SPInterstitialOffer *offer in response.orderedOffers) {
        if ([self canShowInterstitialForOffer:offer]) {
            [self fireNotification:SPInterstitialEventTypeFill offer:offer];
            return offer;
        }

        // Checks if the adapter is integrated. A no_fill should not be sent in this case.
        if ([self adapterForNetworkName:offer.networkName]) {
            [self fireNotification:SPInterstitialEventTypeNoFill offer:offer];
        }
    }
    return nil;
}

- (BOOL)canShowInterstitialForOffer:(SPInterstitialOffer *)offer
{
    id<SPInterstitialNetworkAdapter> adapter = [self adapterForNetworkName:offer.networkName];

    if (!adapter) {
        [self fireNotification:SPInterstitialEventTypeNoSDK offer:offer];
        SPLogError(@"Interstitial Adapter for %@ could not be found", offer.networkName);
        return NO;
    }

    [adapter setDelegate:self];

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:offer.arbitraryData];
    dict[SPInterstitialClientOfferDataRequestIdKey] = self.lastRequestID;
    dict[SPInterstitialClientOfferDataAdIdKey] = offer.adId;
    adapter.offerData = [NSDictionary dictionaryWithDictionary:dict];

    [self fireNotification:SPInterstitialEventTypeRequest offer:offer];

    return [adapter canShowInterstitial];
}

#pragma mark - Showing an interstitial

- (void)showInterstitialFromViewController:(UIViewController *)parentViewController
{
    if (self.state != SPInterstitialClientReadyToShowInterstitialState) {
        NSString *errorDescription =
        [NSString stringWithFormat:@"%s is not ready to show any interstitial offer.", __PRETTY_FUNCTION__];
        [self failWithInvalidStateErrorWithDescription:errorDescription];
        return;
    }
    self.state = SPInterstitialClientShowingInterstitialState;

    id<SPInterstitialNetworkAdapter> adapter = [self adapterForNetworkName:self.selectedOffer.networkName];

    [adapter showInterstitialFromViewController:parentViewController];
}

#pragma mark - SPInterstitialNetworkAdapterDelegate

- (void)adapterDidShowInterstitial:(id<SPInterstitialNetworkAdapter>)adapter
{
    [self fireNotification:SPInterstitialEventTypeImpression offer:self.selectedOffer];
    self.state = SPInterstitialClientReadyToCheckOffersState;
    [self.delegate interstitialClientDidShowInterstitial:self];
}


- (void)adapter:(id<SPInterstitialNetworkAdapter>)adapter
didDismissInterstitialWithReason:(SPInterstitialDismissReason)dismissReason
{
    switch (dismissReason) {
    case SPInterstitialDismissReasonUserClickedOnAd:
        [self fireNotification:SPInterstitialEventTypeClick offer:self.selectedOffer];
        break;
    default:
        [self fireNotification:SPInterstitialEventTypeClose offer:self.selectedOffer];
        break;
    }

    [self.delegate interstitialClient:self didDismissInterstitialWithReason:dismissReason];
}


- (void)adapter:(id<SPInterstitialNetworkAdapter>)adapter didFailWithError:(NSError *)error
{
    SPLogError(@"Error received from %@: %@", adapter.networkName, [error localizedDescription]);
    NSString *adId = adapter.offerData[SPInterstitialClientOfferDataAdIdKey];
    NSString *request_id = adapter.offerData[SPInterstitialClientOfferDataRequestIdKey];

    [self fireNotification:SPInterstitialEventTypeError network:adapter.networkName adId:adId requestId:request_id];
    [self failWithError:error];
}


#pragma mark - Errors

- (void)callDelegateWithNoOffers
{
    if ([self.delegate respondsToSelector:@selector(interstitialClient:canShowInterstitial:)]) {
        [self.delegate interstitialClient:self canShowInterstitial:NO];
    }
}


- (void)failWithCannotInstantiateAdapterErrorWithDescription:(NSString *)description
{
    NSError *error = [NSError errorWithDomain:SPInterstitialClientErrorDomain
                                         code:SPInterstitialClientCannotInstantiateAdapterErrorCode
                                     userInfo:@{ SPInterstitialClientErrorLoggableDescriptionKey: description }];

    [self failWithError:error];
}


- (void)failWithInvalidStateErrorWithDescription:(NSString *)description
{
    NSError *error = [NSError errorWithDomain:SPInterstitialClientErrorDomain
                                         code:SPInterstitialClientInvalidStateErrorCode
                                     userInfo:@{ SPInterstitialClientErrorLoggableDescriptionKey: description }];

    [self failWithError:error];
}


- (void)failWithErrorDescription:(NSString *)errorDescription underlyingError:(NSError *)underlyingError
{
    NSError *error = [NSError errorWithDomain:SPInterstitialClientErrorDomain
                                         code:SPInterstitialClientConnectionErrorCode
                                     userInfo:@{
                                                 SPInterstitialClientErrorLoggableDescriptionKey: errorDescription,
                                                 NSUnderlyingErrorKey: underlyingError
                                              }];

    [self failWithError:error];
}


- (void)failWithError:(NSError *)error
{
    [self.delegate interstitialClient:self didFailWithError:error];
}


- (void)clearCredentials
{
    self.credentials = nil;
}


#pragma mark - Helper methods

- (void)fireNotification:(SPInterstitialEventType)eventType
                 network:(NSString *)networkName
                    adId:(NSString *)adId
               requestId:(NSString *)requestId
{
    SPInterstitialEvent *event =
    [[SPInterstitialEvent alloc] initWithEventType:eventType network:networkName adId:adId requestId:requestId];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPInterstitialEventNotification object:event];
}


- (void)fireNotification:(SPInterstitialEventType)eventType offer:(SPInterstitialOffer *)offer
{
    [self fireNotification:eventType network:offer.networkName adId:offer.adId requestId:self.lastRequestID];
}

@end

NSString *SPStringFromInterstitialDismissReason(SPInterstitialDismissReason reason)
{
    switch (reason) {
    case SPInterstitialDismissReasonUnknown:
        return @"SPInterstitialDismissReasonUnknown";
    case SPInterstitialDismissReasonUserClickedOnAd:
        return @"SPInterstitialDismissReasonUserClickedOnAd";
    case SPInterstitialDismissReasonUserClosedAd:
        return @"SPInterstitialDismissReasonUserClosedAd";
    }
}
