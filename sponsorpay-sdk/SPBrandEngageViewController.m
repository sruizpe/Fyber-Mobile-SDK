//
//  SPBrandEngageViewController.m
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <os/object.h>

#import "SPBrandEngageViewController.h"
#import "SPBrandEngageWebView.h"
#import "SPVideoPlayerViewController.h"
#import "SPVideoPlayerStateDelegate.h"
#import "SPConstants.h"
#import "SPOrientationHelper.h"
#import "SPLogger.h"
#import "NSString+SPURLEncoding.h"
#import "SPVersionChecker.h"


// Video events and parameters
static NSString *const SPVideoEventPlaying = @"playing";
static NSString *const SPVideoEventCancel = @"cancel";
static NSString *const SPVideoEventEnded = @"ended";
static NSString *const SPVideoEventClickThrough = @"clickThrough";
static NSString *const SPVideoEventTimeUpdate = @"timeupdate";

static NSString *const SPVideoParameterDuration = @"duration";
static NSString *const SPVideoParameterCurrentTime = @"currentTime";


@interface SPBrandEngageViewController ()<SPVideoPlaybackStateDelegate>

@property (nonatomic, strong) SPBrandEngageWebView *webView;

@property (nonatomic, strong) SPVideoPlayerViewController *videoViewController;

@property (copy, nonatomic) NSString *tpnName;
@property (copy, nonatomic) NSString *video;

#if OS_OBJECT_HAVE_OBJC_SUPPORT
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
#else
@property (nonatomic, assign) dispatch_semaphore_t semaphore;
#endif


@end

@implementation SPBrandEngageViewController {
    BOOL _viewDidAppearPreviously;
}

#pragma mark - Housekeeping

- (id)initWithWebView:(SPBrandEngageWebView *)webView
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.wantsFullScreenLayout = YES;
        self.webView = webView;
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc
{
    [self.webView setDelegate:nil];
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.webView) {
        SPLogError(@"Brand Engage View Controller's Web View is nil!");
        return;
    }

    if (SPFoundationVersionNumber < NSFoundationVersionNumber_iOS_6_0) { // <-- fix targeted to iOS 5
        self.view.frame = [SPOrientationHelper fullScreenFrameForInterfaceOrientation:self.interfaceOrientation];
    }

    if (!self.webView.superview) { // viewWillAppear could be called after the full screen video has finished playing
        self.webView.frame = self.view.frame;
        self.webView.alpha = 0.0;
        [self.view addSubview:self.webView];
    }

    [self performSelector:@selector(fadeWebViewIn) withObject:nil afterDelay:kSPDelayForFadingWebViewIn];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // When the orientation change happens and the UIWebview is not currently shown (like when
    // playing a video with the native player), the UIWebView is not notified. So we'll force it
    [self refreshWebViewOrientation];
    if (!_viewDidAppearPreviously) {
        _viewDidAppearPreviously = YES;
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.webView) {
        self.webView.alpha = 0.0;
    }
}

#pragma mark - Orientation management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

#endif


#pragma mark - Status bar preference

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark -

- (void)fadeWebViewIn
{
    [UIView animateWithDuration:kSPDurationForFadeWebViewInAnimation animations:^{ self.webView.alpha = 1.0; }];
}

#pragma mark - SPVideoPlaybackDelegate methods
- (void)playVideoFromNetwork:(NSString *)network
                       video:(NSString *)video
                   showAlert:(BOOL)showAlert
                alertMessage:(NSString *)alertMessage
             clickThroughURL:(NSURL *)clickThroughURL
{
    self.tpnName = network;
    self.video = video;

    NSString *decodedVideoURL = [video SPURLDecodedString];
    NSURL *videoURL = [NSURL URLWithString:decodedVideoURL];

    // Sometimes we might receive an offer without a scheme, just //s3.amazonaws.com/..., for example.
    // In these cases we append the http scheme
    if (![videoURL scheme]) {
        decodedVideoURL = [NSString stringWithFormat:@"http:%@", decodedVideoURL];
        videoURL = [NSURL URLWithString:decodedVideoURL];
    }

    self.semaphore = dispatch_semaphore_create(0);
    SPVideoPlayerViewController *playerViewController = [[SPVideoPlayerViewController alloc] initWithVideo:videoURL
                                                                                                 showAlert:showAlert
                                                                                              alertMessage:alertMessage
                                                                                           clickThroughUrl:clickThroughURL];
    playerViewController.delegate = self;
    self.videoViewController = playerViewController;

    __weak SPBrandEngageViewController *weakSelf = self;
    [self presentViewController:playerViewController animated:YES completion:^{
        dispatch_semaphore_signal(weakSelf.semaphore);
    }];
}

- (void)timeUpdate:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    [self.webView notifyOfVideoEvent:SPVideoEventTimeUpdate
                              forTPN:self.tpnName
                         contextData:@{
                             SPTPNIDParameter: self.video,
                             SPVideoParameterCurrentTime: @(currentTime),
                             SPVideoParameterDuration: @(duration)
                         }];
}

#pragma mark - SPVideoPlaybackStateDelegate
- (void)videoPlaybackStartedWithDuration:(NSTimeInterval)duration
{
    [self.webView notifyOfVideoEvent:SPVideoEventPlaying
                              forTPN:self.tpnName
                         contextData:@{
                             SPTPNIDParameter: self.video,
                             SPVideoParameterDuration: @(duration)
                         }];
}

- (void)videoPlaybackEnded:(BOOL)videoWasAborted
{
    // In case of an error (invalid URL, for example), the controller will be dismissed while
    // still being presented. To fix this, we are creating a semaphore while the player is being presented
    __weak SPBrandEngageViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);

        dispatch_async(dispatch_get_main_queue(), ^(void) {


            [weakSelf.webView notifyOfVideoEvent:videoWasAborted ? SPVideoEventCancel : SPVideoEventEnded
                                          forTPN:weakSelf.tpnName
                                     contextData:@{ SPTPNIDParameter : weakSelf.video }];

            [weakSelf.videoViewController
                    dismissViewControllerAnimated:!videoWasAborted
                                       completion:^{
                                           weakSelf.videoViewController = nil;
                                       }];
        });

#if OS_OBJECT_HAVE_OBJC_SUPPORT
#else
        dispatch_release(weakSelf.semaphore);
#endif
    });
}

- (void)refreshWebViewOrientation
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"$(window).trigger('orientationchange')"];
}
- (void)browserWillOpen
{
    [self.webView notifyOfVideoEvent:SPVideoEventClickThrough
                              forTPN:self.tpnName
                         contextData:@{ SPTPNIDParameter: self.video }];
}

@end
