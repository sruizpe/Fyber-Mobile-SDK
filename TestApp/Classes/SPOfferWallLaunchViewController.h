//
//  SPOfferWallLaunchViewController.h
//  SponsorPay Sample App
//
//  Created by David Davila on 1/14/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPTestAppBaseViewController.h"

@interface SPOfferWallLaunchViewController : SPTestAppBaseViewController

@property (strong, nonatomic) IBOutlet UISwitch *closeOnFinishSwitch;
@property (strong, nonatomic) IBOutlet UIView *parametersGroup;
@property (strong, nonatomic) IBOutlet UIButton *launchOfferWallButton;

- (IBAction)launchOfferWall;

@end
