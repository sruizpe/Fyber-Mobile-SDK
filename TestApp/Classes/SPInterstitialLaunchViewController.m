//
//  SPInterstitialLaunchViewController.m
//  SponsorPayTestApp
//
//  Created by David Davila on 02/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialLaunchViewController.h"

// SponsorPay Test App.
#import "SPStrings.h"


#define LogInvocation NSLog(@"%s", __PRETTY_FUNCTION__)


#pragma mark  

@interface SPInterstitialLaunchViewController ()

@property (readonly, strong, nonatomic) SPInterstitialClient *interstitialClient;

@end


#pragma mark  
#pragma mark  
#pragma mark  

@implementation SPInterstitialLaunchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark  
#pragma mark Actions

- (IBAction)requestInterstitial:(id)sender
{
    [self showActivityIndication];
    [SponsorPaySDK checkInterstitialAvailable:self];
}

- (IBAction)launchInterstitial:(id)sender
{
    [SponsorPaySDK showInterstitialFromViewController:self];
}

#pragma mark - SPInterstitialClientDelegate

- (void)interstitialClient:(SPInterstitialClient *)client canShowInterstitial:(BOOL)canShowInterstitial
{
    LogInvocation;
    self.launchInterstitialButton.enabled = canShowInterstitial;
    [self stopActivityIndication];
}

- (void)interstitialClientDidShowInterstitial:(SPInterstitialClient *)client
{
    LogInvocation;
}

- (void)interstitialClient:(SPInterstitialClient *)client
didDismissInterstitialWithReason:(SPInterstitialDismissReason)dismissReason
{
    LogInvocation;
    self.launchInterstitialButton.enabled = NO;

    // Dismiss reason
    NSString *desc =
    [NSString stringWithFormat:@"Interstitial dismissed with reason: %@", SPStringFromInterstitialDismissReason(dismissReason)];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Dismiss reason" message:desc delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
    [alertView show];
}

- (void)interstitialClient:(SPInterstitialClient *)client didFailWithError:(NSError *)error
{
    LogInvocation;
    NSLog(@"error=%@", error);
    NSString *desc = [NSString stringWithFormat:@"Interstitial client failed with error: %@", error];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Interstitial error"
                                                        message:desc
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end

#pragma mark
