//
//  SPMBEWebView.m
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPBrandEngageWebView.h"
#import "SPBrandEngageWebViewDelegate.h"
#import "SPLogger.h"
#import "NSURL+SPParametersParsing.h"
#import "NSURL+SPDescription.h"
#import "NSString+SPURLEncoding.h"
#import "NSDictionary+SPSerialization.h"
#import "SPResourceLoader.h"
#import "SPConstants.h"
#import "SPSchemeParser.h"
#import "SPScheme.h"

// TODO: Change all of these to static NSStrings
NSTimeInterval const SPMBEStartOfferTimeout = (NSTimeInterval)10.0;
NSString *const SPMBEWebViewJavascriptErrorDomain = @"SPMBEWebViewJavascriptErrorDomain";

NSString *const SPRequestStatusParameterStartedValue = @"STARTED";
NSString *const SPRequestStatusParameterCloseFinishedValue = @"CLOSE_FINISHED";
NSString *const SPRequestStatusParameterCloseAbortedValue = @"CLOSE_ABORTED";
NSString *const SPRequestStatusParameterError = @"ERROR";

NSString *const SPJsInvocationStartOffer = @"Sponsorpay.MBE.SDKInterface.do_start()";
NSString *const SPJsInvocationNotify = @"Sponsorpay.MBE.SDKInterface.notify";
NSString *const SPJsInvocationGetOffer = @"Sponsorpay.MBE.SDKInterface.do_getOffer()";

@interface SPBrandEngageWebView ()

@property (strong) UIButton *closeButton;

- (void)processSponsorPayScheme:(NSURL *)url;
- (void)javascriptReportedOffers:(NSInteger)numberOfOffers;
- (void)javascriptStartStatusNotificationReceivedWithStatus:(NSString *)status
                               followOfferURLParameterValue:(NSString *)urlString;
- (void)javascriptExitNotificationReceivedWithOfferURLParameterValue:(NSString *)urlParametervalue;

- (void)startOfferTimerDue;
- (void)showCloseButton;
- (void)hideCloseButton;
- (void)closeButtonWasTapped;

@end

@implementation SPBrandEngageWebView {
    BOOL _startNotificationReceived;
}

#pragma mark - Properties

@synthesize brandEngageDelegate;

@synthesize closeButton = _closeButton;

#pragma mark - Housekeeping

- (id)init
{
    self = [super init];
    if (self) {
        self.mediaPlaybackRequiresUserAction = NO;
        self.allowsInlineMediaPlayback = YES;
        self.scrollView.scrollEnabled = NO;
        self.delegate = self;
    }
    SPLogDebug(@"MBEWebView %x initialized", [self hash]);

    return self;
}

- (void)dealloc
{
    SPLogDebug(@"MBEWebView %x is being deallocated", [self hash]);
    self.delegate = nil;
}

#pragma mark - UIWebView delegate methods

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];

#warning TO REMOVE: Mock for testing purpose


    NSString *scheme = [url scheme];
    if ([scheme isEqualToString:SPCustomURLScheme]) {
        [self processSponsorPayScheme:url];
        return NO;
    }
    SPLogDebug(@"[BET] Webview will start loading request: %@ with navigation type: %d", [request.URL SPPrettyDescription], navigationType);
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    switch (error.code) {
    case 102: // Loadingus interruptus
        SPLogDebug(@"Loading of BEWebView (%x) was interrupted. This is normal if we are, for instance, leaving the "
                   @"app to follow an offer.",
                   [self hash]);
        break;
    case -1004: // "Could not connect to the server."
    case -1009: // "The Internet connection appears to be offline." error
        SPLogError(@"BEWebView (%x) couldn't load due to a network issue: %d, %@", [self hash], error.code, error.localizedDescription);
        if (self.delegate) {
            [self.brandEngageDelegate brandEngageWebView:self didFailWithError:error];
        }
        break;
    default:
        SPLogError(@"Brand Engage webView:(%x) didFailLoadWithError: %d %@", [self hash], error.code, error.localizedDescription);
        break;
    }
}

#pragma mark -

- (void)javascriptReportedOffers:(NSInteger)numberOfOffers
{
    if (brandEngageDelegate) {
        [brandEngageDelegate brandEngageWebView:self javascriptReportedOffers:numberOfOffers];
    }
}

- (void)javascriptStartStatusNotificationReceivedWithStatus:(NSString *)status
                               followOfferURLParameterValue:(NSString *)encodedURLString
{
    if ([status isEqualToString:SPRequestStatusParameterStartedValue]) {
        _startNotificationReceived = YES;
        [self hideCloseButton];
        if (brandEngageDelegate) {
            [brandEngageDelegate brandEngageWebViewJavascriptOnStarted:self];
        }
    } else if ([status isEqualToString:SPRequestStatusParameterCloseFinishedValue]) {
        [self exitCheckingForOfferURL:encodedURLString];
    } else if ([status isEqualToString:SPRequestStatusParameterCloseAbortedValue]) {
        if (brandEngageDelegate) {
            [brandEngageDelegate brandEngageWebViewOnAborted:self];
        }
    } else if ([status isEqualToString:SPRequestStatusParameterError]) {
        if (brandEngageDelegate) {
            NSError *errorToReport = [NSError errorWithDomain:SPMBEWebViewJavascriptErrorDomain code:0 userInfo:nil];
            [brandEngageDelegate brandEngageWebView:self didFailWithError:errorToReport];
        }
    }
}

- (void)javascriptExitNotificationReceivedWithOfferURLParameterValue:(NSString *)encodedURLString
{
    [self exitCheckingForOfferURL:encodedURLString];
}

- (void)exitCheckingForOfferURL:(NSString *)encodedURLString
{
    if (brandEngageDelegate) {
        NSURL *offerURL = nil;
        if (encodedURLString && ![encodedURLString isEqualToString:@""]) {
            if (encodedURLString) {
                NSString *unencodedURLString = [encodedURLString SPURLDecodedString];
                offerURL = [NSURL URLWithString:unencodedURLString];
            }
        }
        [brandEngageDelegate brandEngageWebView:self requestsToCloseFollowingOfferURL:offerURL];
    }
}

- (void)startOfferTimerDue
{
    if (!_startNotificationReceived) {
        [self showCloseButton];
    }
}

- (void)showCloseButton
{
#define kSPMBENativeCloseButtonSideSize 32
#define kSPMBENativeCloseButtonInsetSize 4
#define kSPMBENativeCloseButtonMarginRight 4
#define kSPMBENativeCloseButtonMarginTop 4

#define kSPMBENativeCloseButtonFadeAnimationDuration 1.0

    if (!self.closeButton) {
        CGFloat xPosition = CGRectGetWidth(self.bounds) - kSPMBENativeCloseButtonMarginRight - kSPMBENativeCloseButtonSideSize;
        UIButton *closeButton =
        [[UIButton alloc] initWithFrame:CGRectMake(xPosition, kSPMBENativeCloseButtonMarginTop, kSPMBENativeCloseButtonSideSize, kSPMBENativeCloseButtonSideSize)];
        closeButton.contentEdgeInsets = UIEdgeInsetsMake(kSPMBENativeCloseButtonInsetSize,
                                                         kSPMBENativeCloseButtonInsetSize,
                                                         kSPMBENativeCloseButtonInsetSize,
                                                         kSPMBENativeCloseButtonInsetSize);
        closeButton.backgroundColor = [UIColor clearColor];
        [closeButton setImage:[self closeButtonImage] forState:UIControlStateNormal];
        [closeButton addTarget:self
                        action:@selector(closeButtonWasTapped)
              forControlEvents:UIControlEventTouchUpInside];
        self.closeButton = closeButton;
    }

    self.closeButton.alpha = 0.0;

    [UIView animateWithDuration:kSPMBENativeCloseButtonFadeAnimationDuration
                     animations:^{ self.closeButton.alpha = 1.0; }];

    [self addSubview:self.closeButton];
}

- (UIImage *)closeButtonImage
{
    return [SPResourceLoader imageWithName:@"SPCloseX"];
}

- (void)hideCloseButton
{
    if (self.closeButton && self.closeButton.superview) {
        [UIView animateWithDuration:kSPMBENativeCloseButtonFadeAnimationDuration
        animations:^{ self.closeButton.alpha = 0.0; }
        completion:^(BOOL finished) { [self.closeButton removeFromSuperview]; }];
    }
}


- (void)closeButtonWasTapped
{
    if (brandEngageDelegate) {
        [brandEngageDelegate brandEngageWebViewOnAborted:self];
    }
}

- (BOOL)currentOfferUsesTPN
{
    NSString *usesTPNJSON = [self stringByEvaluatingJavaScriptFromString:SPJsInvocationGetOffer];
    NSError *error;
    id usesTPN = [NSJSONSerialization JSONObjectWithData:[usesTPNJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                 options:0
                                                   error:&error];

    NSNumber *r = usesTPN[@"uses_tpn"];

    SPLogInfo(@"Current offer will be played through a third party network: %@", [r boolValue] ? @"YES" : @"NO");

    return [r boolValue];
}

- (void)startOffer
{
    _startNotificationReceived = NO;

    SPLogDebug(@"[BET] invoking %@", SPJsInvocationStartOffer);
    [self stringByEvaluatingJavaScriptFromString:SPJsInvocationStartOffer];
    [self performSelector:@selector(startOfferTimerDue) withObject:nil afterDelay:SPMBEStartOfferTimeout];
}

#pragma mark - SponsorPay schema handling

- (void)processSponsorPayScheme:(NSURL *)url
{
    SPLogDebug(@"Processing SponsorPay scheme: %@", [url absoluteString]);
    
    SPScheme *scheme = [SPSchemeParser parseUrl:url];
    NSDictionary *parameters = [url SPQueryDictionary];

    switch (scheme.commandType) {
        case SPSchemeCommandTypeRequestOffers:
            [self javascriptReportedOffers:scheme.numberOfOffers];
            break;

        case SPSchemeCommandTypeStart:
            [self javascriptStartStatusNotificationReceivedWithStatus:scheme.status followOfferURLParameterValue:scheme.urlString];
            break;

        case SPSchemeCommandTypeExit:
            [self javascriptExitNotificationReceivedWithOfferURLParameterValue:scheme.urlString];
            break;

        case SPSchemeCommandTypeValidate:
            SPLogInfo(@"MBE client asks to validate a third party network: %@", scheme.tpnName);
            [self.brandEngageDelegate brandEngageWebView:self requestsValidationOfTPN:scheme.tpnName contextData:scheme.contextData];

            break;

        case SPSchemeCommandTypePlayLocal:
            SPLogInfo(@"[BET] MBE client asks to play an offer from a third party network: %@", scheme.tpnName);

            [self.brandEngageDelegate brandEngageWebView:self
                               playVideoFromLocalNetwork:scheme.tpnName
                                                   video:parameters[SPTPNIDParameter]
                                               showAlert:scheme.showAlert
                                            alertMessage:scheme.alertMessage
                                         clickThroughURL:scheme.clickThroughUrl];
            break;

        case SPSchemeCommandTypePlayTPN:{
            SPLogInfo(@"[BET] MBE client asks to play an offer from a third party network: %@", scheme.tpnName);
            [self.brandEngageDelegate brandEngageWebView:self requestsPlayVideoOfTPN:scheme.tpnName contextData:scheme.contextData];

            break;
        }

        case SPSchemeCommandTypeInstall:
            SPLogDebug(@"Opening store with app id: %@", scheme.appId);
            [self.brandEngageDelegate brandEngageWebView:self requestsStoreWithAppId:scheme.appId affiliateToken:scheme.affiliateToken campaignToken:scheme.campaignToken];

            break;

        default:
            break;
    }
}

#pragma mark -

- (void)notifyOfValidationResult:(NSString *)validationResult
                          forTPN:(NSString *)tpnName
                     contextData:(NSDictionary *)contextData
{
    NSString *contextDataString;
    if ([contextData count]) {
        contextDataString = [NSString stringWithFormat:@", %@", [contextData SPComponentsJoined]];
    }

    NSString *js =
    [NSString stringWithFormat:@"%@('validate', {tpn:'%@', result:'%@'%@})", SPJsInvocationNotify, tpnName, validationResult, contextDataString];

    SPLogDebug(@"%s (%x) invoking javascript in the webview: %@", __PRETTY_FUNCTION__, [self hash], js);

    [self stringByEvaluatingJavaScriptFromString:js];
}

- (void)notifyOfVideoEvent:(NSString *)videoEventName forTPN:(NSString *)tpnName contextData:(NSDictionary *)contextData
{
    NSString *contextDataString;
    if ([contextData count]) {
        contextDataString = [NSString stringWithFormat:@", %@", [contextData SPComponentsJoined]];
    }

    NSString *js =
    [NSString stringWithFormat:@"%@('play', {tpn:'%@', result:'%@'%@})", SPJsInvocationNotify, tpnName, videoEventName, contextDataString];

    SPLogDebug(@"%s (%x) invoking javascript in the webview: %@", __PRETTY_FUNCTION__, [self hash], js);

    [self stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark -

- (void)loadRequest:(NSURLRequest *)request
{
    SPLogDebug(@"MBEWebView %x will load request with URL %@", [self hash], request.URL.absoluteString);

    [super loadRequest:request];
}

@end
