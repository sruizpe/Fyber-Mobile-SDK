//
//  SPCredentialsManager.h
//  SponsorPayTestApp
//
//  Created by David Davila on 21/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPCredentials;

extern NSString *const SPNoCredentialsException;
extern NSString *const SPNoUniqueCredentialsException;
extern NSString *const SPInvalidCredentialsTokenException;

@interface SPCredentialsManager : NSObject

- (void)addCredentialsItem:(SPCredentials *)credentials forToken:(NSString *)token;

- (SPCredentials *)currentCredentials;

- (SPCredentials *)credentialsForToken:(NSString *)credentialsToken;

- (void)clearCredentials;

- (void)setCurrentCredentialsWithToken:(NSString *)credentialsToken;


- (SPCredentials *)setConfigurationValue:(id)value
                                  forKey:(NSString *)key
                  inCredentialsWithToken:(NSString *)token;

- (void)setConfigurationValueInAllCredentials:(id)value
                                       forKey:(NSString *)key;

@end
