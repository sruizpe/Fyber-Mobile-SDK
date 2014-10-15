//
//  SPBrandEngageClient_SDKPrivate.h
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import "SPBrandEngageClient.h"
#import "SPMediationCoordinator.h"

@class SPCredentials;

@interface SPBrandEngageClient (SDKPrivate)

@property (nonatomic, retain, readwrite) NSString *currencyName;
@property (nonatomic, retain, readwrite) SPMediationCoordinator *mediationCoordinator;

- (id)initWithCredentials:(SPCredentials *)credentials;

@end
