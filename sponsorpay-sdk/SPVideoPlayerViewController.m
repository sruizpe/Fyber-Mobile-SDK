
//
//  SPVideoPlayer.m
//  SPVideoPlayer
//
//  Created by Daniel Barden on 25/12/13.
//  Copyright (c) 2013 SponsorPay GmbH. All rights reserved.
//

#import "SPCloseButton.h"
#import "SPCountdownView.h"
#import "SPMicroBrowserViewController.h"
#import "SPLoadingIndicator.h"
#import "SPVideoPlayerViewController.h"
#import "SPVideoPlayerStateDelegate.h"
#import "SPLogger.h"
#import "SPReachability.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MPMoviePlayerController.h>

#define IS_IPAD() UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

static const NSInteger SPUpdateInterval = 1;
static const NSTimeInterval SPVideoTimeout = 15;
static const CGFloat SPTappablePaddingForCloseButton = 15.0;

@interface SPVideoPlayerViewController () <UIAlertViewDelegate, SPMicroBrowserDelegate>

@property (nonatomic, strong) MPMoviePlayerController *player;

@property (nonatomic, strong) SPLoadingIndicator *loadingIndicator;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) SPCountdownView *countdownView;
@property (nonatomic, strong) UIAlertView *closeAlert;

@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong) NSTimer *playbackTimer;

// Timer in case the video takes a long time to start playing
@property (nonatomic, strong) NSTimer *stallTimer;

@property (nonatomic, assign) BOOL hasVideoPlayed;

// Click Through
@property (nonatomic, strong) UIView *clickThroughView;
@property (nonatomic, strong) SPMicroBrowserViewController *microBrowser;

@end

@implementation SPVideoPlayerViewController

#pragma mark - NSObject lifecycle
- (id)initWithVideo:(NSURL *)url showAlert:(BOOL)showAlert alertMessage:(NSString *)alertMessage clickThroughUrl:(NSURL *)clickThroughURL
{
    self = [super init];
    if (self) {
        _showAlert = showAlert;
        _alertMessage = alertMessage;
        _videoURL = url;
        _clickThroughURL = clickThroughURL;
    }

    return self;
}

- (void)dealloc
{
    SPLogDebug(@"%s", __PRETTY_FUNCTION__);
    if ([self.playbackTimer isValid]) {
        [self.playbackTimer invalidate];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _delegate = nil;
}

#pragma mark - ViewController Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackStateDidChange:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieLoadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieDurationAvailable:)
                                                 name:MPMovieDurationAvailableNotification
                                               object:nil];

    // Close button
    SPCloseButton *closeButton = [[SPCloseButton alloc] initWithFrame:[self frameForCloseButton] paddingInsets:[self paddingInsetsForCloseButton]];
    [closeButton addTarget:self action:@selector(userTappedClose) forControlEvents:UIControlEventTouchUpInside];

    self.closeButton = closeButton;

    // Countdown timer
    SPCountdownView *countdownView = [[SPCountdownView alloc] initWithFrame:[self frameForCountDownView]];
    countdownView.frame = [self frameForCountDownView];
    self.countdownView = countdownView;

    // Player configuration
    self.player = [[MPMoviePlayerController alloc] init];
    self.player.controlStyle = MPMovieControlStyleNone;
    self.player.scalingMode = IS_IPAD() ? MPMovieScalingModeAspectFit : MPMovieScalingModeAspectFill;

    self.player.contentURL = self.videoURL;
    [self.player prepareToPlay];

    // On iOS 5, if the user taps twice, it will zoom. We don't want that
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_6_0) {
        self.player.view.userInteractionEnabled = NO;
    }


    [self.view addSubview:_player.view];

    // Stall Timer
    self.stallTimer = [NSTimer scheduledTimerWithTimeInterval:SPVideoTimeout target:self selector:@selector(videoStalledAtStartup) userInfo:nil repeats:NO];

    // Close button
    self.closeButton  = [[SPCloseButton alloc] initWithFrame:CGRectZero paddingInsets:[self paddingInsetsForCloseButton]];
    self.closeButton.hidden = YES;
    [self.closeButton addTarget:self action:@selector(userTappedClose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];


    // Countdown timer
    self.countdownView = [[SPCountdownView alloc] initWithFrame:CGRectZero];
    self.countdownView.hidden = YES;
    [self.view addSubview:self.countdownView];


    // Loading spinner
    self.loadingIndicator = [[SPLoadingIndicator alloc] initFullScreen:YES showSpinner:YES];

    // Click-Through UIView
    [self startClickThroughView];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.loadingIndicator presentWithAnimationTypes:SPAnimationTypeNone];

    [self adjustControlsToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [self adjustVideoToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.player.view.frame = self.view.bounds;
    self.closeButton.frame = [self frameForCloseButton];
    self.countdownView.frame = [self frameForCountDownView];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.loadingIndicator dismiss];
    [super viewWillDisappear:animated];
}

#pragma mark - Private Methods

- (void)trackProgress
{
    [self printPlayerState];
    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        [self.delegate timeUpdate:self.player.currentPlaybackTime duration:self.player.duration];
    }
}

- (void)userTappedClose
{
    if (self.showAlert) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Exit Video", nil)
                                                            message:self.alertMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"Resume Video"
                                                  otherButtonTitles:@"Close Video", nil];
        [self.player pause];
        [alertView show];
        self.closeAlert = alertView;
    } else {
        [self closeVideo];
    }
}

#pragma mark - NSNotifications from the player

- (void)movieLoadStateDidChange:(NSNotification *)notification
{
    SPLogDebug(@"Video Load changed to state %d", self.player.loadState);
    if (self.player.loadState & MPMovieLoadStateStalled) {
        SPLogDebug(@"Player stalled %f, %f", self.player.playableDuration, self.player.currentPlaybackTime);
        [self.player stop];
    }
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    SPLogDebug(@"Movie playback changed to state %@", [NSNumber numberWithInteger:self.player.playbackState]);
    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        [self.loadingIndicator dismiss];
        [self.countdownView play];
        [self.countdownView updateCountdownWithTimeInterval:self.player.currentPlaybackTime];

        // Actions that should be executed the first time the player actually starts playing
        if (!self.hasVideoPlayed) {
            self.hasVideoPlayed = YES;
            [self.stallTimer invalidate];

            self.closeButton.hidden = NO;
            [self.delegate videoPlaybackStartedWithDuration:self.player.duration];
            if (self.player.duration < 30) {
                self.countdownView.hidden = NO;
            }
        }
    }

    if (self.player.playbackState == MPMoviePlaybackStatePaused) {
        [self.countdownView pause];
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    // If the video was fully watched, the final state is MPMoviePlayback state is paused and currentPlaybackTime
    // is the total duration. In case when the video was stopped or stalled, the state is stopped and
    // currentPlaybackTime is 0.

    BOOL videoWasAborted = (self.player.currentPlaybackTime < self.player.duration ||
            self.player.currentPlaybackTime == 0);

    SPLogDebug(@"Playback finished. Video was aborted: %@", videoWasAborted ? @"YES" : @"NO");
    [self videoPlaybackFinishedWithAbort:videoWasAborted];
}

- (void)movieDurationAvailable:(NSNotification *)notification
{
    SPLogDebug(@"Video duration is: %@", [NSNumber numberWithDouble:self.player.duration]);
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:SPUpdateInterval target:self selector:@selector(trackProgress) userInfo:nil repeats:YES];
    self.countdownView.duration = self.player.duration;
}

#pragma mark - System Notifications
- (void)willResignActive:(NSNotification *)notification
{
    [self.closeAlert dismissWithClickedButtonIndex:-1 animated:NO];
    [self videoPlaybackFinishedWithAbort:YES];
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self.player play];
            break;
        case 1:
            [self closeVideo];
            break;
    }
}

#pragma mark - Micro browser
- (void)openClickThroughBrowser
{
    // It might happen that the browser tries to open right before receiving the movie ended notification.
    // This causes the player to be dismissed while showing the browser, what causes a conflict in the transitions.
    NSTimeInterval browserGuardBand = 0.2;
    if (self.player.currentPlaybackTime >= (self.player.duration - browserGuardBand)) {
        SPLogDebug(@"Could not open the micro browser - movie ended: Current Playback %f Duration: %f", self.player.currentPlaybackTime, self.player.duration);
        return;
    }

    [self.player pause];

    SPMicroBrowserViewController *microBrowser = [[SPMicroBrowserViewController alloc] init];
    microBrowser.delegate = self;
    [microBrowser loadRequest:[NSURLRequest requestWithURL:self.clickThroughURL]];
    [self.delegate browserWillOpen];
    [self presentViewController:microBrowser animated:YES completion:nil];
}

- (void)microBrowserDidClose:(SPMicroBrowserViewController *)browser
{
    [self.player play];
}

#pragma mark - Geometry related

// Based on the requirements, the video player will only be displayed using the landscape orientation
- (CGRect)frameForCloseButton
{
    CGRect screenBounds = self.view.bounds;
    CGRect frame = CGRectZero;
    CGFloat padding = SPTappablePaddingForCloseButton;
    CGFloat doublePadding = 2 * padding;
    CGFloat baseRectSide = 30 + doublePadding;
    CGFloat borderOffset = 16 - padding;

    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        frame = CGRectMake(screenBounds.size.width - (baseRectSide + borderOffset),
                           screenBounds.size.height - (baseRectSide + borderOffset),
                           baseRectSide,
                           baseRectSide);
    } else {
        frame = CGRectMake(screenBounds.size.width - (baseRectSide + borderOffset),
                           screenBounds.origin.y + borderOffset,
                           baseRectSide,
                           baseRectSide);
    }

    return frame;
}

- (UIEdgeInsets)paddingInsetsForCloseButton
{
    return UIEdgeInsetsMake(SPTappablePaddingForCloseButton,
            SPTappablePaddingForCloseButton,
            SPTappablePaddingForCloseButton,
            SPTappablePaddingForCloseButton);
}

- (CGRect)frameForCountDownView
{
    CGRect screenBounds = self.view.bounds;

    CGFloat baseRectSide = 30;
    CGFloat borderOffset = 16;
    CGRect frame;

    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        frame = CGRectMake(screenBounds.size.width - (baseRectSide + borderOffset),
                           screenBounds.origin.y + borderOffset,
                           baseRectSide,
                           baseRectSide);
    } else {
        frame = CGRectMake(screenBounds.origin.x + borderOffset,
                           screenBounds.origin.y + borderOffset,
                           baseRectSide,
                           baseRectSide);

    }
    return  frame;
}

- (CGRect)frameForVideo
{
    CGFloat width = self.view.frame.size.width > self.view.frame.size.height ? self.view.frame.size.width : self.view.frame.size.height;
    CGFloat height = self.view.frame.size.width < self.view.frame.size.height ? self.view.frame.size.width : self.view.frame.size.height;

    return  CGRectMake(0, 0, width, height);
}

- (void)adjustControlsToOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    CGRect closeButtonFrame = [self frameForCloseButton];
    self.closeButton.center = CGPointMake(CGRectGetMidX(closeButtonFrame), CGRectGetMidY(closeButtonFrame));
    self.countdownView.frame = [self frameForCountDownView];

    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        self.countdownView.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else {
        self.countdownView.transform = CGAffineTransformIdentity;
    }
}

- (void)adjustVideoToOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        self.player.view.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.player.view.frame = self.view.frame;
    } else {
        self.player.view.transform = CGAffineTransformIdentity;
        self.player.view.frame = [self frameForVideo];
    }

    self.clickThroughView.frame = self.player.view.frame;
}

- (void)startClickThroughView
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Check that we support the scheme
        BOOL isSchemeValid = ([self.clickThroughURL.scheme isEqualToString:@"http"] ||
                [self.clickThroughURL.scheme isEqualToString:@"https"]);

        if (!isSchemeValid) {
            return;
        }

        // Checks for server reachability
        SPReachability *reachability = [SPReachability reachabilityWithHostName:self.clickThroughURL.host];
        BOOL reachable = [reachability currentReachabilityStatus];

        if (!reachable) {
            return;
        }

        // Adds the ClickThrough view to the view hierarchy
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *clickThroughView = [[UIView alloc] initWithFrame:self.player.view.frame];
            clickThroughView.backgroundColor = [UIColor clearColor];
            clickThroughView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:clickThroughView];

            [self.view bringSubviewToFront:self.closeButton];
            [self.view bringSubviewToFront:self.countdownView];

            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openClickThroughBrowser)];
            [clickThroughView addGestureRecognizer:tapGestureRecognizer];
            self.clickThroughView = clickThroughView;
        });

    });
}

#pragma mark - Misc
- (void)closeVideo
{
    [self.player stop];
}

- (void)videoPlaybackFinishedWithAbort:(BOOL)videoWasAborted
{
    [self printPlayerState];
    [self.playbackTimer invalidate];
    [self.loadingIndicator dismiss];
    [self.delegate videoPlaybackEnded:videoWasAborted];
}

- (void)videoStalledAtStartup
{
    SPLogError(@"Could not download the video - timeout to start playing reached");
    [self videoPlaybackFinishedWithAbort:YES];
}

- (void)printPlayerState
{
    SPLogDebug(@"MoviePlayer Load state     %d", self.player.loadState);
    SPLogDebug(@"MoviePlayer Playback state %d", self.player.playbackState);
    SPLogDebug(@"MoviePlayer Playback time %f", self.player.currentPlaybackTime);
    SPLogDebug(@"MoviePlayer Playable time %f", self.player.playableDuration);
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [UIView setAnimationsEnabled:NO];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{

    [self adjustControlsToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [self adjustVideoToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [UIView setAnimationsEnabled:YES];
}

@end
