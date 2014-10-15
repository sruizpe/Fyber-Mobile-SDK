//
//  SPMediationCoordinator.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 5/16/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPTPNMediationTypes.h"

#ifdef ENABLE_MOCK
#import "SPMockTPNAdapter.h"
#endif

@interface SPMediationCoordinator : NSObject

@property (strong) UIViewController *hostViewController;

#ifdef ENABLE_MOCK
@property (strong) SPMockTPNAdapter *mockAdapter;
#endif

- (BOOL)providerAvailable:(NSString *)providerKey;
- (void)videosFromProvider:(NSString *)providerKey available:(SPTPNValidationResultBlock)callback;
- (void)playVideoFromProvider:(NSString *)providerKey eventsCallback:(SPTPNVideoEventsHandlerBlock)eventsCallback;

@end
