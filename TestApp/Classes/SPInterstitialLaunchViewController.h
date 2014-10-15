//
//  SPInterstitialLaunchViewController.h
//  SponsorPayTestApp
//
//  Created by David Davila on 02/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPTestAppBaseViewController.h"

@interface SPInterstitialLaunchViewController : SPTestAppBaseViewController<SPInterstitialClientDelegate>

@property (weak, nonatomic) IBOutlet UIButton *requestInterstitialButton;
@property (weak, nonatomic) IBOutlet UIButton *launchInterstitialButton;

- (IBAction)requestInterstitial:(id)sender;
- (IBAction)launchInterstitial:(id)sender;
@end
