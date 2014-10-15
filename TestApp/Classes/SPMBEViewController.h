//
//  SPMBEViewController.h
//  SponsorPay Sample App
//
//  Created by David Davila on 1/14/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import "SPTestAppBaseViewController.h"

@interface SPMBEViewController : SPTestAppBaseViewController <SPBrandEngageClientDelegate>

@property (strong, nonatomic) IBOutlet UIButton *startButton;
@property (strong, nonatomic) IBOutlet UISwitch *engagementCompletedNotificationSwitch;
@property (strong, nonatomic) IBOutlet UIView *mainGroup;

- (IBAction)requestOffers;
- (IBAction)start;

@end
