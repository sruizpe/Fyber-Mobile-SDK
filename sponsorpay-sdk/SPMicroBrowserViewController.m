//
//  SPMicroBrowserViewController.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 22/03/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPMicroBrowserViewController.h"
#import "SPLogger.h"
#import "SPVersionChecker.h"

@interface SPMicroBrowserViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIWebView *webView;

@property (strong, nonatomic) UILabel *titleLabel;
@end

@implementation SPMicroBrowserViewController

- (id)init
{
    self = [super init];
    if (self) {
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    _webView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    // Navigation Bar
    self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.view.frame), 44)];

    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        self.navBar.frame = CGRectMake(CGRectGetWidth(self.view.frame) - CGRectGetHeight(self.view.frame) / 2 - 22,
                                       CGRectGetHeight(self.view.frame) / 2 - 22,
                                       CGRectGetHeight(self.view.frame),
                                       44);
        CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2);
        self.navBar.transform = rotate;
    }

    // Navigation Bar Title
    UINavigationItem *navItem = [UINavigationItem alloc];

    // Uses an UILabel for iOS 7
    if (SPFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        NSUInteger labelInset = 64;
        UILabel *titleLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.view.frame) - labelInset, 21)];
        titleLabel.text = NSLocalizedString(@"Loading...", nil);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        navItem.titleView = titleLabel;

        [titleLabel sizeToFit];
        self.titleLabel = titleLabel;
    } else {
        navItem.title = NSLocalizedString(@"Loading...", nil);
    }

    [self.navBar pushNavigationItem:navItem animated:NO];

    // Navigation Bar Done Button
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(closeView)];

    self.navBar.topItem.leftBarButtonItem = barButtonItem;

    // Customizes the UINavigationBar for iOS 7
    if (SPFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.navBar.translucent = YES;
        self.navBar.barStyle = UIBarStyleDefault;
    }

    // UIWebview
    [self setupWebView];

    [self.view addSubview:self.webView];
    [self.view addSubview:self.navBar];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // After applying the transform in UINavigationBar, the Done button is offsetted and we need to put it in its
    // correct location once again.
    if (SPFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 &&
        UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        // Navigation Bar Done Button
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                       target:self
                                                                                       action:@selector(closeView)];

        self.navBar.topItem.leftBarButtonItem = barButtonItem;

        for (UIView *subview in self.navBar.subviews) {
            for (UIView *view in subview.subviews) {
                if ([view isKindOfClass:[UILabel class]]) {
                    CGFloat diff = subview.frame.origin.y - view.frame.origin.y - 4;
                    view.transform = CGAffineTransformMakeTranslation(0, diff);
                }
            }
        }
    }
}

- (void)loadRequest:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

- (void)setupWebView
{
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        self.webView.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.webView.frame =
        CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width - 44, self.view.frame.size.height);
    } else {
        self.webView.frame =
        CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 44, self.view.frame.size.width, self.view.frame.size.height);
    }

    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}
#pragma mark - UIWebView delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *navBarTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    SPLogDebug(@"Setting window tite to %@", navBarTitle);
    if ([navBarTitle length]) {
        if (SPFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            self.titleLabel.text = navBarTitle;
        } else {
            self.navBar.topItem.title = navBarTitle;
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    SPLogDebug(@"%@", [error localizedDescription]);
}

#pragma mark - UINavigation actions
- (void)closeView
{
    [self dismissViewControllerAnimated:YES completion:^{ [self.delegate microBrowserDidClose:self]; }];
}

#pragma mark - Geometry related methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
