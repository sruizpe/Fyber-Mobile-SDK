//
//  SPBrandEngageClient.m
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPBrandEngageClient.h"
#import "SPBrandEngageClient_SDKPrivate.h"

// SponsorPay SDK.
#import "SPLogger.h"
#import "SPToast.h"
#import "SPReachability.h"
#import "SPVirtualCurrencyServerConnector.h"
#import "SPVirtualCurrencyServerConnector_SDKPrivate.h"
#import "SPConstants.h"
#import "SPTargetedNotificationFilter.h"
#import "SPLoadingIndicator.h"
#import "SPBrandEngageViewController.h"
#import "SPURLGenerator.h"
#import "SPMediationCoordinator.h"
#import "SPBrandEngageWebView.h"
#import "SPBrandEngageWebViewDelegate.h"
#import "SPConstants.h"
#import "SPCredentials.h"
#import "SPVersionChecker.h"

#import <StoreKit/StoreKit.h>
#import "SPConnectionHelper.h"

NSTimeInterval const SPMBERequestOffersTimeout = (NSTimeInterval)10.0;
NSString *const SPMBERewardNotificationText = @"Thanks! Your reward will be paid out shortly";

NSString *const SPMBEErrorDialogTitle = @"Error";
NSString *const SPMBEErrorDialogMessageDefault = @"We're sorry, something went wrong. Please try again.";
NSString *const SPMBEErrorDialogMessageOffline = @"Your Internet connection has been lost. Please try again later.";
NSString *const SPMBEErrorDialogButtonTitleDismiss = @"Dismiss";

NSInteger const SPMBEErrorDialogCloseTag = -1;
NSInteger const SPMBEErrorDialogGenericTag = 0;
NSInteger const SPMBEErrorDialogStoreKitTag = 1;

NSString *const kSPMBEURLParamValueClient = @"sdk";
NSString *const kSPMBEURLParamValuePlatform = @"ios";
NSString *const kSPMBEURLParamValueAdFormat = @"video";
NSInteger const kSPMBEURLParamValueRewarded = 1;

typedef NS_ENUM(NSInteger, SPBEClientOffersRequestStatus) {
    SPBEClientOffersRequestStatusMustQueryServerForOffers,
    SPBEClientOffersRequestStatusQueryingServerForOffers,
    SPBEClientOffersRequestStatusReadyToShowOffers,
    SPBEClientOffersRequestStatusShowingOffers
} SPBrandEngageClientOffersRequestStatus;


@interface SPBrandEngageClient ()<SPBrandEngageWebViewDelegate, UIAlertViewDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, strong) SPBrandEngageWebView *BEWebView;
@property (strong) SPBrandEngageViewController *activeBEViewController;
@property (strong) UIViewController *viewControllerToRestore;

@property (nonatomic, strong) SPCredentials *credentials;
@property (nonatomic, strong, readwrite) NSString *currencyName;

@property (strong) NSTimer *timeoutTimer;
@property (nonatomic, strong, readwrite) SPMediationCoordinator *mediationCoordinator;
@property (assign) BOOL playingThroughTPN;

@property (assign) BOOL playVideoCallbackReceived;

@property (nonatomic, strong) SPLoadingIndicator *loadingStoreKitView;

@end


@implementation SPBrandEngageClient {
    SPBEClientOffersRequestStatus _offersRequestStatus;
    NSMutableDictionary *_customParams;
    BOOL _mustRestoreStatusBarOnPlayerDismissal;
    SPReachability *_internetReachability;
    SPLoadingIndicator *_loadingProgressView;
}

#pragma mark - Properties

- (BOOL)setCustomParamWithKey:(NSString *)key value:(NSString *)value
{
    if (_customParams && [[_customParams objectForKey:key] isEqualToString:value]) {
        return YES;
    }

    if (![self canChangePublisherParameters]) {
        SPLogError(@"Cannot add custom parameter while a request to the server is going on"
                    " or an offer is being presented to the user.");
    } else {
        if (!_customParams) {
            _customParams = [[NSMutableDictionary alloc] init];
        }
        [_customParams setObject:value forKey:key];
        [self didChangePublisherParameters];
        return YES;
    }

    return NO;
}

- (BOOL)canChangePublisherParameters
{
    return (_offersRequestStatus == SPBEClientOffersRequestStatusMustQueryServerForOffers) ||
           (_offersRequestStatus == SPBEClientOffersRequestStatusReadyToShowOffers);
}

- (void)didChangePublisherParameters
{
    _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
}

@synthesize delegate = _delegate;

@synthesize BEWebView = _BEWebView;

- (SPBrandEngageWebView *)BEWebView
{
    if (!_BEWebView) {
        _BEWebView = [[SPBrandEngageWebView alloc] init];
        _BEWebView.brandEngageDelegate = self;
    }
    return _BEWebView;
}

@synthesize activeBEViewController = _activeBEViewController;

#pragma mark - Initializing and deallocing

- (id)initWithCredentials:(SPCredentials *)credentials;
{
    self = [super init];

    if (self) {
        _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
        _credentials = credentials;

        self.shouldShowRewardNotificationOnEngagementCompleted = YES;
        self.loadingStoreKitView = [[SPLoadingIndicator alloc] initFullScreen:NO showSpinner:YES];

        [self setUpInternetReachabilityNotifier];
        [self registerForCurrencyNameChangeNotification];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (self.timeoutTimer.isValid) {
        [self.timeoutTimer invalidate];
    }
}

#pragma mark - Public methods
- (BOOL)canRequestOffers
{
    return _offersRequestStatus == SPBEClientOffersRequestStatusMustQueryServerForOffers ||
           _offersRequestStatus == SPBEClientOffersRequestStatusReadyToShowOffers;
}

- (BOOL)requestOffers
{
    if (![self canRequestOffers]) {
        SPLogWarn(
        @"SPBrandEngageClient cannot request offers at this point. "
         "It might be requesting offers right now or an offer might be currently being presented to the user.");

        return NO;
    }

    if (SPFoundationVersionNumber >= NSFoundationVersionNumber_iOS_5_0) {
        _offersRequestStatus = SPBEClientOffersRequestStatusQueryingServerForOffers;

        [self.BEWebView loadRequest:[self requestForWebViewMBEJsCore]];

        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:SPMBERequestOffersTimeout
                                                             target:self
                                                           selector:@selector(requestOffersTimerDue)
                                                           userInfo:nil
                                                            repeats:NO];
    } else {
        // iOS 5 or newer is required.
        [self performSelector:@selector(callDelegateWithNoOffers) withObject:nil afterDelay:0.0];
    }

    return YES;
}

- (BOOL)canStartOffers
{
    return (_offersRequestStatus == SPBEClientOffersRequestStatusReadyToShowOffers);
}

- (BOOL)startWithParentViewController:(UIViewController *)parentViewController
{
    if (![self canStartOffers]) {
        SPLogError(@"SPBrandEngageClient is not ready to show offers. Call -requestOffers: "
                    "and wait until your delegate is called with the confirmation that offers have been received.");

        [self invokeDelegateWithStatus:ERROR];

        return NO;
    }

//    if (_internetReachability.currentReachabilityStatus == SPNetworkStatusNotReachable) {
//        SPLogError(@"SPBrandEngageClient could not show the video due to lack of Internet connectivity");
//        NSError *error = [NSError errorWithDomain:@"com.sponsorpay.mobileBrandEngageError" code:-1009 userInfo:@{NSLocalizedDescriptionKey: @"The Internet connection appears to be offline"}];
//        [self showErrorAlertWithMessage:error.localizedDescription tag:SPMBEErrorDialogGenericTag];
//        [self invokeDelegateWithStatus:ERROR];
//
//        return NO;
//    }

    [[SPConnectionHelper sharedInstance] checkConnectivityWithFailure:^{
        SPLogError(@"SPBrandEngageClient could not show the video due to lack of Internet connectivity");
        NSError *error = [NSError errorWithDomain:@"com.sponsorpay.mobileBrandEngageError" code:-1009 userInfo:@{NSLocalizedDescriptionKey: @"The Internet connection appears to be offline"}];
        [self showErrorAlertWithMessage:error.localizedDescription tag:SPMBEErrorDialogCloseTag];
        [self invokeDelegateWithStatus:ERROR];
    }];

    _offersRequestStatus = SPBEClientOffersRequestStatusShowingOffers;

    BOOL isTPNOffer = self.playingThroughTPN = [self.BEWebView currentOfferUsesTPN];

    if (isTPNOffer) {
        self.mediationCoordinator.hostViewController = parentViewController;
        [self animateLoadingViewIn];
        self.playVideoCallbackReceived = NO;
        [self performSelector:@selector(playTPNVideoDue) withObject:nil afterDelay:SPMBEStartOfferTimeout];

        [self.BEWebView startOffer];
    } else {
        [self presentBEViewControllerWithParent:parentViewController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }


    return YES;
}

- (void)presentBEViewControllerWithParent:(UIViewController *)parentViewController
{
    if (![UIApplication sharedApplication].statusBarHidden) {
        SPLogDebug(@"Hiding status bar");
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        _mustRestoreStatusBarOnPlayerDismissal = YES;
    }

    SPBrandEngageViewController *brandEngageVC = [[SPBrandEngageViewController alloc] initWithWebView:self.BEWebView];

    self.activeBEViewController = brandEngageVC;

    void (^simpleBlock)(void) = ^{ [self.BEWebView startOffer]; };

    if (SPFoundationVersionNumber >= NSFoundationVersionNumber_iOS_6_0) {
        [parentViewController presentViewController:self.activeBEViewController animated:YES completion:simpleBlock];
    } else {
        self.viewControllerToRestore = [[self class] swapRootViewControllerTo:brandEngageVC
                                                         withAnimationOptions:UIViewAnimationOptionTransitionCurlDown
                                                                   completion:simpleBlock];
    }
}

#pragma mark - Interrupting engagement if the host app enters background

- (void)didEnterBackground
{
    _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
    [self engagementDidFinish];

    [self invokeDelegateWithStatus:CLOSE_ABORTED];
}

#pragma mark - SPBrandEngageWebViewControllerDelegate methods

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView javascriptReportedOffers:(NSInteger)numberOfOffers
{
    SPLogDebug(@"%s BEWebView=%x offers=%d", __PRETTY_FUNCTION__, [BEWebView hash], numberOfOffers);

    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;

    BOOL areOffersAvailable = (numberOfOffers > 0);

    _offersRequestStatus = areOffersAvailable ? SPBEClientOffersRequestStatusReadyToShowOffers :
                                                SPBEClientOffersRequestStatusMustQueryServerForOffers;

    if ([self.delegate respondsToSelector:@selector(brandEngageClient:didReceiveOffers:)]) {
        [self.delegate brandEngageClient:self didReceiveOffers:areOffersAvailable];
    }
}

- (void)brandEngageWebViewJavascriptOnStarted:(SPBrandEngageWebView *)BEWebView
{
    SPLogDebug(@"OnStarted event received");

    [self invokeDelegateWithStatus:STARTED];
}

- (void)brandEngageWebViewOnAborted:(SPBrandEngageWebView *)BEWebView
{
    [self engagementDidFinish];

    _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
    [self invokeDelegateWithStatus:CLOSE_ABORTED];
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView didFailWithError:(NSError *)error
{
    SPBEClientOffersRequestStatus preErrorStatus = _offersRequestStatus;
    _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;

    // Show dialog only if we are showing offers
    if (preErrorStatus == SPBEClientOffersRequestStatusShowingOffers) {
        NSString *errorMessage = nil;

        if ([error.domain isEqualToString:SPMBEWebViewJavascriptErrorDomain]) {
            errorMessage = SPMBEErrorDialogMessageDefault;
        } else {
            errorMessage = SPMBEErrorDialogMessageOffline;
        }

        [self showErrorAlertWithMessage:errorMessage tag:SPMBEErrorDialogGenericTag];
    } else if (preErrorStatus == SPBEClientOffersRequestStatusQueryingServerForOffers) {
        [self invokeDelegateWithStatus:ERROR];
    }
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView requestsToCloseFollowingOfferURL:(NSURL *)offerURL
{
    BOOL willOpenURL = NO;
    if (offerURL) {
        willOpenURL = [[UIApplication sharedApplication] openURL:offerURL];
    }

    if (willOpenURL) {
        [BEWebView stopLoading];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userReturnedAfterFollowingOffer)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        SPLogDebug(@"Application will follow offer url: %@", offerURL);
    }

    [self engagementDidFinish];

    if (!willOpenURL) {
        [self showRewardNotification];
    }

    _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
    [self invokeDelegateWithStatus:CLOSE_FINISHED];
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
   requestsValidationOfTPN:(NSString *)tpnName
               contextData:(NSDictionary *)contextData
{
    SPTPNValidationResultBlock resultBlock = ^(NSString *tpnKey, SPTPNValidationResult validationResult) {
    NSString *validationResultString = SPTPNValidationResultToString(validationResult);

    SPLogInfo(@"Videos from %@ validation result: %@", tpnKey, validationResultString);

    [BEWebView notifyOfValidationResult:validationResultString forTPN:tpnKey contextData:contextData];
    };

    [self.mediationCoordinator videosFromProvider:tpnName available:resultBlock];
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
    requestsPlayVideoOfTPN:(NSString *)tpnName
               contextData:(NSDictionary *)contextData
{
    [self animateLoadingViewOut];
    self.playVideoCallbackReceived = YES;
    SPTPNVideoEventsHandlerBlock eventsHandlerBlock = ^(NSString *tpnKey, SPTPNVideoEvent event) {
    NSString *eventName = SPTPNVideoEventToString(event);
    SPLogDebug(@"Video event from %@: %@", tpnKey, eventName);

    [BEWebView notifyOfVideoEvent:eventName forTPN:tpnName contextData:contextData];
    };

    if (self.mediationCoordinator.hostViewController) {
        [self.mediationCoordinator playVideoFromProvider:tpnName eventsCallback:eventsHandlerBlock];
    } // else - function called after timeout
}

- (void)playTPNVideoDue
{
    if (!self.playVideoCallbackReceived) {
        [self animateLoadingViewOut];
        SPLogError(@"Could not play the video - timeout to start playing reached");
        [self invokeDelegateWithStatus:ERROR];
        _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
        self.mediationCoordinator.hostViewController = nil;
    }
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView requestsStoreWithAppId:(NSString *)appId affiliateToken:(NSString *)affiliateToken campaignToken:(NSString *)campaignToken
{
    [BEWebView stopLoading];
    if ([SKStoreProductViewController class]) {
        [self openStoreWithAppId:appId affiliateToken:affiliateToken campaignToken:campaignToken];
    } else {
        NSURL *offerURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.com/apps/id%@", appId]];
        [self brandEngageWebView:BEWebView requestsToCloseFollowingOfferURL:offerURL];
    }
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
 playVideoFromLocalNetwork:(NSString *)network
                     video:(NSString *)video
                 showAlert:(BOOL)showAlert
              alertMessage:(NSString *)alertMessage
           clickThroughURL:(NSURL *)clickThroughURL
{
    // Since our video player supports only landscape, the end card should only support landscape as well
    [self.activeBEViewController playVideoFromNetwork:network
                                                video:video
                                            showAlert:showAlert
                                         alertMessage:alertMessage
                                      clickThroughURL:clickThroughURL];
}

#pragma mark - StoreKit methods
- (void)openStoreWithAppId:(NSString *)appId affiliateToken:(NSString *)affiliateToken campaignToken:(NSString *)campaignToken
{
    SPLogDebug(@"Opening app store with appId %@", appId);
    [self.loadingStoreKitView presentWithAnimationTypes:SPAnimationTypeFade];
    SKStoreProductViewController *productViewController = [[SKStoreProductViewController alloc] init];
    productViewController.delegate = self;

    NSMutableDictionary *mutableParams = [@{ SKStoreProductParameterITunesItemIdentifier:appId } mutableCopy];

#ifdef __IPHONE_8_0
    if (SPFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        if (!affiliateToken) {
            affiliateToken = @"";
        }

        if (!campaignToken) {
            campaignToken = @"";
        }

        NSDictionary *params = @{
                                 SKStoreProductParameterAffiliateToken:affiliateToken,
                                 SKStoreProductParameterCampaignToken:campaignToken
                                 };

        [mutableParams addEntriesFromDictionary:params];
    }
#endif

    [productViewController loadProductWithParameters:[mutableParams copy] completionBlock:^(BOOL result, NSError *error) {
        [self.loadingStoreKitView dismiss];
        if (!error) {
            [self.activeBEViewController presentViewController:productViewController animated:YES completion:nil];
        } else {
            [self showErrorAlertWithMessage:[error localizedDescription] tag:SPMBEErrorDialogStoreKitTag];
        }
    }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self dismissProductViewController];
}

- (void)dismissProductViewController
{
    [self showRewardNotification];
    [self engagementDidFinish];
    _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
    [self invokeDelegateWithStatus:CLOSE_FINISHED];
}
#pragma mark - Handling user's return after completing engagement

- (void)userReturnedAfterFollowingOffer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    SPLogDebug(@"User returned to app after following offer. Will show notification.");

    [self showRewardNotification];
}

#pragma mark - Internet connection status change management

- (void)setUpInternetReachabilityNotifier
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kSPReachabilityChangedNotification
                                               object:nil];

    if (!_internetReachability) {
        _internetReachability = [SPReachability reachabilityForInternetConnection];
    }

    [_internetReachability startNotifier];
}

// Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification *)note
{
    if (!self.activeBEViewController) {
        return;
    }

    SPReachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[SPReachability class]]);

    SPNetworkStatus currentNetworkStatus = [curReach currentReachabilityStatus];

    switch (currentNetworkStatus) {
    case SPNetworkStatusReachableViaWiFi:
        SPLogDebug(@"Internet is now reachable via WiFi");
        break;
    case SPNetworkStatusReachableViaWWAN:
        SPLogDebug(@"Internet is now reachable via WWAN (cellular connection)");
        break;
    case SPNetworkStatusNotReachable:
        SPLogDebug(@"Connection to the internet has been lost");
        [self didLoseInternetConnection];
        break;
    default:
        SPLogDebug(@"Unexpected network status received: %d", currentNetworkStatus);
        break;
    }
}

- (void)didLoseInternetConnection
{
    if (_offersRequestStatus == SPBEClientOffersRequestStatusShowingOffers) {
        _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;
        [self showErrorAlertWithMessage:SPMBEErrorDialogMessageOffline tag:SPMBEErrorDialogGenericTag];
    }
}

#pragma mark - Error alerts

- (void)showErrorAlertWithMessage:(NSString *)message tag:(NSInteger)tag
{
    UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:SPMBEErrorDialogTitle
                                                             message:message
                                                            delegate:self
                                                   cancelButtonTitle:SPMBEErrorDialogButtonTitleDismiss
                                                   otherButtonTitles:nil];
    if (tag) {
        errorAlertView.tag = tag;
    }

    [errorAlertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case SPMBEErrorDialogGenericTag:
            [self engagementDidFinish];
            [self invokeDelegateWithStatus:ERROR];
            break;

        case SPMBEErrorDialogStoreKitTag:
            [self dismissProductViewController];
            break;

        case SPMBEErrorDialogCloseTag:
            _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;

            if (_mustRestoreStatusBarOnPlayerDismissal) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
                SPLogDebug(@"Restored status bar");
            }

            [self dismissEngagementViewController];

            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIApplicationDidEnterBackgroundNotification
                                                          object:nil];
            break;

        default:
            break;
    }
}

#pragma mark - Utility methods

- (NSURL *)requestURLForMBE
{
    SPURLGenerator *urlGenerator = [SPURLGenerator URLGeneratorWithEndpoint:SPURLEndpointMBEJSCore];

    [urlGenerator setCredentials:self.credentials];

    [urlGenerator setParameterWithKey:kSPURLParamKeyCurrencyName stringValue:self.currencyName];
    [urlGenerator setParameterWithKey:@"sdk" stringValue:@"on"];
    [urlGenerator setParameterWithKey:kSPURLParamKeyClient stringValue:kSPMBEURLParamValueClient];
    [urlGenerator setParameterWithKey:kSPURLParamKeyPlatform stringValue:kSPMBEURLParamValuePlatform];
    [urlGenerator setParameterWithKey:kSPURLParamKeyRewarded integerValue:kSPMBEURLParamValueRewarded];
    [urlGenerator setParameterWithKey:kSPURLParamKeyAdFormat stringValue:kSPMBEURLParamValueAdFormat];

    if (_customParams) {
        [urlGenerator setParametersFromDictionary:_customParams];
    }
    return [urlGenerator generatedURL];
}

- (NSURLRequest *)requestForWebViewMBEJsCore
{
    NSURL *requestURL = [self requestURLForMBE];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

    return request;
}

- (void)engagementDidFinish
{
    SPLogInfo(@"Engagement finished");

    if (self.playingThroughTPN) {
        self.BEWebView = nil;
        return;
    }

    if (_mustRestoreStatusBarOnPlayerDismissal) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        SPLogDebug(@"Restored status bar");
    }

    [self dismissEngagementViewController];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

- (void)dismissEngagementViewController
{
    if (!_activeBEViewController) {
        SPLogWarn(@"no active BEViewController to dismiss");
        return;
    }

    if (SPFoundationVersionNumber >= NSFoundationVersionNumber_iOS_6_0) {
        [_activeBEViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        NSAssert(self.viewControllerToRestore, @"%@.viewControllerToRestore is nil!", [self class]);

        [[self class] swapRootViewControllerTo:self.viewControllerToRestore
                          withAnimationOptions:UIViewAnimationOptionTransitionCurlUp
                                    completion:nil];
        self.viewControllerToRestore = nil;
    }

    [self.BEWebView removeFromSuperview];
    self.BEWebView = nil;

    _activeBEViewController = nil;
}

- (void)requestOffersTimerDue
{
    if (_offersRequestStatus == SPBEClientOffersRequestStatusQueryingServerForOffers) {
        SPLogError(@"Requesting offers timed out");
        [self.BEWebView stopLoading];
        self.BEWebView = nil;
        _offersRequestStatus = SPBEClientOffersRequestStatusMustQueryServerForOffers;

        [self callDelegateWithNoOffers];
    }
}

- (void)callDelegateWithNoOffers
{
    if ([self.delegate respondsToSelector:@selector(brandEngageClient:didReceiveOffers:)]) {
        [self.delegate brandEngageClient:self didReceiveOffers:NO];
    }
}

- (void)showRewardNotification
{
    SPLogDebug(@"showRewardNotification");

    if (!self.shouldShowRewardNotificationOnEngagementCompleted) {
        return;
    }

    SPToastSettings *const settings = [SPToastSettings toastSettings];

    settings.duration = SPToastDurationNormal;
    settings.gravity = SPToastGravityBottom;

    (void)[SPToast enqueueToastOfType:SPToastTypeNone withText:SPMBERewardNotificationText settings:settings];
}

- (void)invokeDelegateWithStatus:(SPBrandEngageClientStatus)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(brandEngageClient:didChangeStatus:)]) {
            [self.delegate brandEngageClient:self didChangeStatus:status];
        } else {
            SPLogWarn(@"SP Brand Engage Client Delegate: %@ cannot be notified of status change "
                      "because it doesn't respond to selector brandEngageClient:didChangeStatus:",
                      self.delegate);
        }
    });
}

+ (UIViewController *)swapRootViewControllerTo:(UIViewController *)toVC
                          withAnimationOptions:(UIViewAnimationOptions)animationOptions
                                    completion:(void (^)(void))completion
{
#define kSPRootVCSwapAnimationDuration 1.0

    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *fromVC = keyWindow.rootViewController;
    void (^animationCompletionHandler)(BOOL) = nil;

    if (completion) {
        animationCompletionHandler = ^(BOOL finished) {
        if (finished)
            completion();
        };
    }

    [UIView transitionFromView:fromVC.view
                        toView:toVC.view
                      duration:kSPRootVCSwapAnimationDuration
                       options:animationOptions
                    completion:animationCompletionHandler];

    [keyWindow setRootViewController:toVC];

    return fromVC;
}

#pragma mark - Currency name change notification

- (void)registerForCurrencyNameChangeNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currencyNameChanged:)
                                                 name:SPCurrencyNameChangeNotification
                                               object:nil];
}

- (void)currencyNameChanged:(NSNotification *)notification
{
    if ([SPTargetedNotificationFilter instanceWithAppId:self.credentials.appId
                                                 userId:self.credentials.userId
                            shouldRespondToNotification:notification]) {
        id newCurrencyName = notification.userInfo[SPNewCurrencyNameKey];
        if ([newCurrencyName isKindOfClass:[NSString class]]) {
            self.currencyName = newCurrencyName;
            SPLogInfo(@"%@ currency name is now: %@", self, self.currencyName);
        }
    }
}

#pragma mark - Loading indicator

- (SPLoadingIndicator *)loadingProgressView
{
    if (nil == _loadingProgressView) {
        _loadingProgressView = [[SPLoadingIndicator alloc] initFullScreen:YES showSpinner:NO];
    }

    return _loadingProgressView;
}

- (void)animateLoadingViewIn
{
    [self.loadingProgressView presentWithAnimationTypes:SPAnimationTypeFade];
}

- (void)animateLoadingViewOut
{
    [[self loadingProgressView] dismiss];
}

#pragma mark - NSObject selectors

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {appId=%@ userId=%@}", [super description], self.credentials.appId, self.credentials.userId];
}

#pragma mark - Credentials

- (NSString *)appId
{
    return self.credentials ? self.credentials.appId : nil;
}

- (NSString *)userId
{
    return self.credentials ? self.credentials.userId : nil;
}

@end
