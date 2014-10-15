//
//  SPOfferWallViewController.m
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import "SPOfferWallViewController.h"
#import "SPOfferWallViewController_SDKPrivate.h"
#import "SPLoadingIndicator.h"
#import "SPTargetedNotificationFilter.h"

#import "SPURLGenerator.h"
#import "SPPersistence.h"
#import "SPSchemeParser.h"
#import "SPScheme.h"

#import "SPOrientationHelper.h"
#import "SPLogger.h"
#import "SPConstants.h"
#import <StoreKit/StoreKit.h>
#import "SPVersionChecker.h"
#import "SPReachability.h"

#define SHOULD_OFFERWALL_FINISH_ON_REDIRECT_DEFAULT NO

static const NSUInteger kOfferWallLoadingErrorAlertTag = 10;
static const NSTimeInterval SPOFWDefaultRequestTimeout = 20;
static NSString *const SPOFWRequestTimeout = @"SPOFWRequestTimeout";

@interface SPOfferWallViewController ()<SKStoreProductViewControllerDelegate>

@property (nonatomic, strong) SPCredentials *credentials;
@property (nonatomic, strong) SPLoadingIndicator *loadingProgressView;
@property (nonatomic, strong) SPScheme *sponsorpayParsedScheme;
@property (nonatomic, strong) UIViewController *publisherViewController;

@property (nonatomic, retain) UIWebView *webView;

@property (nonatomic, copy) SPViewControllerDisposalBlock disposalBlock;

@property (nonatomic, assign) BOOL usingLegacyMode;
@property (nonatomic, assign) BOOL shouldRestoreStatusBar;
@property (nonatomic, assign) BOOL alertShowing;

@property (nonatomic, strong) SPReachability *internetReachability;

@property (nonatomic, strong, readwrite) NSString *currencyName;

@property (nonatomic, readwrite, copy) OfferWallCompletionBlock block;

- (void)dismissAnimated:(BOOL)animated withStatus:(SPOfferWallStatus)status;

@end


@implementation SPOfferWallViewController {
    BOOL _usingLegacyMode;
    BOOL _shouldRestoreStatusBar;
}

#pragma mark - Initializers

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        [self registerForCurrencyNameChangeNotification];
        self.usingLegacyMode = NO;

        _alertViewClass = [UIAlertView class];
        _storeKitStoreProductClass = [SKStoreProductViewController class];
    }

    return self;
}

- (id)initWithCredentials:(SPCredentials *)credentials
{
    self = [self init];

    if (self) {
        self.credentials = credentials;
    }

    return self;
}

#pragma mark -  Life Cycle

- (void)loadView
{
    [super loadView];

    UIInterfaceOrientation currentOrientation = [SPOrientationHelper currentStatusBarOrientation];
    CGRect rootViewFrame = [SPOrientationHelper fullScreenFrameForInterfaceOrientation:currentOrientation];

    UIView *rootView = [[UIView alloc] initWithFrame:rootViewFrame];
    rootView.backgroundColor = [UIColor clearColor];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.view = rootView;

    self.loadingProgressView = [[SPLoadingIndicator alloc] init];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;

    if (!self.webView.superview) {
        [self.view addSubview:self.webView];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_usingLegacyMode) {
        [self startLoadingOfferWall];
    }

    self.alertShowing = NO;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    // Hides the status bar before displaying the webview
    if (![UIApplication sharedApplication].statusBarHidden) {
        _shouldRestoreStatusBar = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];

    if (_shouldRestoreStatusBar) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
}


#pragma mark - NSNotification

- (void)appWillEnterForegroundNotification:(NSNotification *)notification
{
    if (self.webView != nil && self.webView.superview != nil) {
        [self.webView reload];
    }
}


#pragma mark - UI

- (void)animateLoadingViewIn
{
    [self.loadingProgressView presentWithAnimationTypes:SPAnimationTypeFade];
}

- (void)animateLoadingViewOut
{
    [[self loadingProgressView] dismiss];
}


#pragma mark - UIWebView

- (void)loadURLInWebView:(NSURL *)url
{

    NSTimeInterval timeout = [self fetchRequestTimeout];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:timeout];
    [self.webView loadRequest:requestObj];
}

- (NSTimeInterval)fetchRequestTimeout
{
    NSNumber *timeout = [[NSBundle mainBundle] objectForInfoDictionaryKey:SPOFWRequestTimeout];

    return timeout ? [timeout doubleValue] : SPOFWDefaultRequestTimeout;
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


#pragma mark - Presentation of publisher's VC

- (void)presentAsChildOfViewController:(UIViewController *)parentViewController
{
    self.publisherViewController = parentViewController;
    [parentViewController presentViewController:self animated:YES completion:nil];
}

- (void)dismissFromPublisherViewControllerAnimated:(BOOL)animated
{
    if (!self.publisherViewController) {
        return;
    }

    UIViewController *publisherVC = self.publisherViewController;

    self.publisherViewController = nil;

    dispatch_async(dispatch_get_main_queue(), self.disposalBlock);

    [publisherVC dismissViewControllerAnimated:animated completion:nil];
}


#pragma mark - Private

- (void)showOfferWallWithParentViewController:(UIViewController *)parentViewController
{
    [self showOfferWallWithParentViewController:parentViewController completion:nil];
}

- (void)showOfferWallWithParentViewController:(UIViewController *)parentViewController
                                   completion:(OfferWallCompletionBlock)block
{
    if (SPFoundationVersionNumber < NSFoundationVersionNumber_iOS_5_0) {
        SPLogError(@"The device is running a version of iOS (%f) that is inferior to the lowest iOS version (%f) "
                   @"compatible with Fyber's SDK",
                   SPFoundationVersionNumber,
                   NSFoundationVersionNumber_iOS_5_0);
        SPLogInfo(@"No offers will be returned");

        if ([self.delegate respondsToSelector:@selector(offerWallViewController:isFinishedWithStatus:)]) {
            [self.delegate offerWallViewController:self isFinishedWithStatus:[@(SPOfferWallStatusNetworkError) intValue]];
        }
        
        return;
    }

    if (block) {
        self.delegate = self;
        self.block = block;
    }

    [self setUpInternetReachabilityNotifier];
    [self presentAsChildOfViewController:parentViewController];
    [self startLoadingOfferWall];
}

- (void)startLoadingOfferWall
{
    NSURL *offerWallURL = [self URLForOfferWall];

    SPLogDebug(@"SponsorPay Mobile Offer Wall will be requested using url: %@", offerWallURL);

    [self animateLoadingViewIn];
    [self loadURLInWebView:offerWallURL];
}

- (NSURL *)URLForOfferWall
{
    SPURLGenerator *urlGenerator = [SPURLGenerator URLGeneratorWithEndpoint:SPURLEndpointOfferWall];
    [urlGenerator setCredentials:self.credentials];
    [urlGenerator setParameterWithKey:kSPURLParamKeyCurrencyName stringValue:self.currencyName];

    [urlGenerator setParametersFromDictionary:self.customParameters];

    return [urlGenerator generatedURL];
}

- (void)webViewDidFinishLoad
{
    [self animateLoadingViewOut];
}

- (void)dismissAnimated:(BOOL)animated withStatus:(SPOfferWallStatus)status
{
    SPLogInfo(@"Dismissing offerwal with status: %d", status);
    [self animateLoadingViewOut];

    if ([self.delegate respondsToSelector:@selector(offerWallViewController:isFinishedWithStatus:)]) {
        [self.delegate offerWallViewController:self isFinishedWithStatus:[@(status) intValue]];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPReachabilityChangedNotification object:nil];

    if (!_usingLegacyMode) {
        [self dismissFromPublisherViewControllerAnimated:animated];
    }
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
        [_internetReachability startNotifier];
    }
}

- (void)reachabilityChanged:(NSNotification *)note
{
    SPReachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[SPReachability class]]);

    SPNetworkStatus currentNetworkStatus = [curReach currentReachabilityStatus];

    if (currentNetworkStatus == SPNetworkStatusNotReachable) {
        if (self.alertShowing) {
            return;
        }

        NSError *error = [NSError errorWithDomain:@"com.sponsorpay.mobileBrandEngageError" code:-1009 userInfo:@{NSLocalizedDescriptionKey: @"The Internet connection appears to be offline"}];
        [self handleWebViewLoadingError:error];
    }
}


#pragma mark - SPOfferWallViewControllerDelegate

- (void)offerWallViewController:(SPOfferWallViewController *)offerWallVC isFinishedWithStatus:(int)status
{
    if (self.block) {
        self.block(status);
        self.block = nil;
    }
}


#pragma mark - Error handling

- (void)handleWebViewLoadingError:(NSError *)error
{
    self.alertShowing = YES;

    UIAlertView *alert = [[self.alertViewClass alloc] initWithTitle:[error localizedDescription]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];

    alert.tag = kOfferWallLoadingErrorAlertTag;
    [alert show];
}


- (void)callDelegateWithNoOffers
{
    if ([self.delegate respondsToSelector:@selector(offerWallViewController:isFinishedWithStatus:)]) {
        [self.delegate offerWallViewController:self isFinishedWithStatus:[@(SPOfferWallStatusNoOffer) intValue]];
    }
}


#pragma mark - UIWebViewDelegate


- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    SPScheme *scheme = [SPSchemeParser parseUrl:request.URL];

    self.sponsorpayParsedScheme = scheme;

    scheme.shouldRequestCloseWhenOpeningExternalURL = self.shouldFinishOnRedirect;
    BOOL shouldContinueLoading = ![scheme isSponsorPayScheme];

    switch (scheme.commandType) {
    // Exit Command
    case SPSchemeCommandTypeExit: {
        BOOL openingExternalDestination = scheme.requestsOpeningExternalDestination;

        if (openingExternalDestination) {
            [[UIApplication sharedApplication] openURL:scheme.externalDestination];
        }

        if (self.sponsorpayParsedScheme.requestsClosing) {
            [self dismissAnimated:!openingExternalDestination withStatus:scheme.closeStatus];
        }
        break;
    }

    // Install Command
    case SPSchemeCommandTypeInstall: {
        if (self.storeKitStoreProductClass) {
            [self openStoreWithAppId:scheme.appId affiliateToken:scheme.affiliateToken campaignToken:scheme.campaignToken];
        } else {
            [self openITunesWithAppId:scheme.appId
                      requestsClosing:scheme.requestsClosing
                          closeStatus:scheme.closeStatus];
        }
        break;
    }

    default:
        break;
    }

    return shouldContinueLoading;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // Error -999 is triggered when the WebView starts a request before the previous one was completed.
    // We assume that kind of error can be safely ignored.
    if ([error code] == -999) {
        return;
    }

    if (!self.sponsorpayParsedScheme.requestsOpeningExternalDestination) {
        if (self.alertShowing) {
            return;
        }

        [self handleWebViewLoadingError:error];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self webViewDidFinishLoad];
}


#pragma mark - Private Methods

- (void)openStoreWithAppId:(NSString *)appId affiliateToken:(NSString *)affiliateToken campaignToken:(NSString *)campaignToken
{
    SPLogDebug(@"Opening StoreKit with App Id: %@", appId);
    SKStoreProductViewController *productViewController = [[self.storeKitStoreProductClass alloc] init];
    productViewController.delegate = self;

    NSMutableDictionary *mutableParams = [@{ SKStoreProductParameterITunesItemIdentifier:appId } mutableCopy];

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

    [productViewController loadProductWithParameters:[mutableParams copy] completionBlock:^(BOOL result, NSError *error) {
        if (!error) {
            [self presentViewController:productViewController animated:YES completion:nil];
        } else {
            UIAlertView *alertView = [[self.alertViewClass alloc] initWithTitle:NSLocalizedString(@"An Error Happened", nil)
                                                                        message:[error localizedDescription]
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                                              otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

- (void)openITunesWithAppId:(NSString *)appId requestsClosing:(BOOL)requestsClosing closeStatus:(NSInteger)closeStatus
{
    NSURL *iTunesURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.com/apps/id%@", appId]];
    SPLogDebug(@"Opening iTunes with URL: %@", iTunesURL);
    [[UIApplication sharedApplication] openURL:iTunesURL];

    if (requestsClosing) {
        [self dismissAnimated:NO withStatus:closeStatus];
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kOfferWallLoadingErrorAlertTag) {
        [self dismissAnimated:YES withStatus:SPOfferWallStatusNetworkError];
        self.alertShowing = NO;
    }
}


#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000

- (NSUInteger)supportedInterfaceOrientations
{
    //    return [self currentStatusBarOrientation];
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

#endif


- (BOOL)prefersStatusBarHidden
{
    return YES;
}


@end
