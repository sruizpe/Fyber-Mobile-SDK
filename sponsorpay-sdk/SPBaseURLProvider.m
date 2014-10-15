//
//  SPBaseURLProvider.m
//  SponsorPayTestApp
//
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPBaseURLProvider.h"

NSString *const kSPActionsBaseURL = @"https://service.sponsorpay.com/actions/v2";
NSString *const kSPInstallsBaseURL = @"https://service.sponsorpay.com/installs/v2";
NSString *const kSPVCSBaseURL = @"https://api.sponsorpay.com/vcs/v1/new_credit.json";
NSString *const kSPMBEBaseURL = @"https://iframe.sponsorpay.com/mbe";
NSString *const kSPOfferWallWBaseURL = @"https://iframe.sponsorpay.com/mobile";
NSString *const kSPInterstitialBaseURL = @"https://engine.sponsorpay.com/interstitial";
NSString *const kSPInterstitialEventURL = @"https://engine.sponsorpay.com/tracker";
NSString *const kSPAdaptersConfigBaseURL = @"https://engine.sponsorpay.com/sdk-config";

NSString *const kSPMBEJSCoreURL = @"http://be.sponsorpay.com/mobile";

@interface SPBaseURLProvider ()

@property (nonatomic, strong) NSDictionary *urlsByKeys;
@property (nonatomic, copy) NSString *ovrrideUrl;
@end

@implementation SPBaseURLProvider

+ (SPBaseURLProvider *)sharedInstance
{
    static SPBaseURLProvider *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPBaseURLProvider alloc] init];
    });

    return sharedInstance;
}

- (id)init
{
    self = [super init];

    if (self) {
        self.urlsByKeys = @{ @(SPURLEndPointActions): kSPActionsBaseURL,
                             @(SPURLEndpointInstalls): kSPInstallsBaseURL,
                             @(SPURLEndpointVCS): kSPVCSBaseURL,
                             @(SPURLEndpointMBE): kSPMBEBaseURL,
                             @(SPURLEndpointOfferWall): kSPOfferWallWBaseURL,
                             @(SPURLEndpointInterstitial): kSPInterstitialBaseURL,
                             @(SPURLEndpointTracker): kSPInterstitialEventURL,
                             @(SPURLEndpointMBEJSCore): kSPMBEJSCoreURL,
                             @(SPURLEndpointAdaptersConfig): kSPAdaptersConfigBaseURL};
    }
    return self;
}

- (NSString *)urlForEndpoint:(SPURLEndpoint)endpoint
{
    NSString *baseUrl = self.ovrrideUrl;
#ifdef ENABLE_STAGING

    if ((!baseUrl || ![baseUrl length]) && self.customProvider) {
        baseUrl = [self.customProvider urlForEndpoint:endpoint];
    }
#endif

    if (!baseUrl || ![baseUrl length]) {
        baseUrl = [self.urlsByKeys objectForKey:@(endpoint)];
    }

    return baseUrl;
}

#ifdef ENABLE_STAGING

- (void)overrideWithUrl:(NSString *)customUrl
{
    self.ovrrideUrl = customUrl;
    if (customUrl) {
        self.customProvider = nil;
    }
}

- (void)setCustomProvider:(id<SPURLProvider>)customProvider
{
    _customProvider = customProvider;

    if (customProvider) {
        self.ovrrideUrl = nil;
    }
}

- (void)restoreUrlsToDefault
{
    self.customProvider = nil;
    self.ovrrideUrl = nil;
}

#endif
@end
