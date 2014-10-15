//
//  SPVCSViewController.h
//  SponsorPay Sample App
//
//  Created by David Davila on 1/14/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import "SPTestAppBaseViewController.h"

@interface SPVCSViewController : SPTestAppBaseViewController<SPVirtualCurrencyConnectionDelegate>

@property (strong, nonatomic) IBOutlet UIView *sendRequestGroup;
@property (strong, nonatomic) IBOutlet UIView *transactionIDsGroup;
@property (strong, nonatomic) IBOutlet UIView *deltaOfCoinsGroup;
@property (strong, nonatomic) IBOutlet UITextView *requestLTIDView;
@property (strong, nonatomic) IBOutlet UITextView *responseLTIDView;
@property (strong, nonatomic) IBOutlet UITextView *responseDeltaOfCoinsView;

- (IBAction)sendDeltaOfCoinsRequest;

@end
