//
//  SPAdvertiserManager.h
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//


/**
 * Singleton for reporting offers to the SponsorPay server.
 */
@interface SPAdvertiserManager : NSObject

+ (SPAdvertiserManager *)advertiserManagerForAppId:(NSString *)appId;

- (void)reportOfferCompletedWithUserId:(NSString *)userId;

- (void)reportActionCompleted:(NSString *)actionId;

@end
