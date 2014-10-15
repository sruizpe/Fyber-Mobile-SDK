//
//  SPInterstitialClient_SDKPrivate.h
//  SponsorPayTestApp
//
//  Created by David Davila on 01/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialClient.h"

@interface SPInterstitialClient (SDKPrivate)

+ (instancetype)sharedClient;

- (void)setCredentials:(SPCredentials *)credentials;
- (void)clearCredentials;
- (void)setForcedDeviceCountryCode:(NSString *)countryCode;

@end
