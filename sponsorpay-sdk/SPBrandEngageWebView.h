//
//  SPMBEWebView.h
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSTimeInterval const SPMBEStartOfferTimeout;
FOUNDATION_EXPORT NSString *const SPMBEWebViewJavascriptErrorDomain;

FOUNDATION_EXPORT NSString *const SPCustomURLScheme;

FOUNDATION_EXPORT NSString *const SPRequestOffersAnswer;
FOUNDATION_EXPORT NSString *const SPNumberOfOffersParameterKey;

FOUNDATION_EXPORT NSString *const SPRequestStartStatus;
FOUNDATION_EXPORT NSString *const SPRequestStatusParameterKey;
FOUNDATION_EXPORT NSString *const SPRequestStatusParameterStartedValue;
FOUNDATION_EXPORT NSString *const SPRequestStatusParameterCloseFinishedValue;
FOUNDATION_EXPORT NSString *const SPRequestStatusParameterCloseAbortedValue;
FOUNDATION_EXPORT NSString *const SPRequestStatusParameterError;

FOUNDATION_EXPORT NSString *const SPThirtPartyNetworkParameter;
FOUNDATION_EXPORT NSString *const SPRequestPlay;

FOUNDATION_EXPORT NSString *const SPRequestExit;
FOUNDATION_EXPORT NSString *const SPRequestURLParameterKey;

FOUNDATION_EXPORT NSString *const SPRequestInstall;
FOUNDATION_EXPORT NSString *const SPRequestInstallAppId;

FOUNDATION_EXPORT NSString *const SPJsInvocationStartOffer;
FOUNDATION_EXPORT NSString *const SPJsInvocationNotify;
FOUNDATION_EXPORT NSString *const SPJsInvocationGetOffer;

FOUNDATION_EXPORT NSString *const SPTPNLocalName;
FOUNDATION_EXPORT NSString *const SPTPNShowAlertParameter;
FOUNDATION_EXPORT NSString *const SPTPNAlertMessageParameter;
FOUNDATION_EXPORT NSString *const SPTPNClickThroughURL;


@protocol SPBrandEngageWebViewDelegate;
@protocol SPVideoPlaybackDelegate;

@interface SPBrandEngageWebView : UIWebView<UIWebViewDelegate>

@property (weak) id<SPBrandEngageWebViewDelegate> brandEngageDelegate;
@property (weak) id<SPVideoPlaybackDelegate> videoPlaybackDelegate;

- (BOOL)currentOfferUsesTPN;
- (void)startOffer;
- (void)notifyOfValidationResult:(NSString *)validationResult
                          forTPN:(NSString *)tpnName
                     contextData:(NSDictionary *)contextData;
- (void)notifyOfVideoEvent:(NSString *)videoEventName
                    forTPN:(NSString *)tpnName
               contextData:(NSDictionary *)contextData;
@end
