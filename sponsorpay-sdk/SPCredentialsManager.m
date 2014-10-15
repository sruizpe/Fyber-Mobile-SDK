//
//  SPCredentialsManager.m
//  SponsorPayTestApp
//
//  Created by David Davila on 21/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPCredentialsManager.h"
#import "SPCredentials.h"
#import "SPLogger.h"

NSString *const SPNoCredentialsException = @"SponsorPayNoCredentialsException";
NSString *const SPNoUniqueCredentialsException = @"SponsorPayNoUniqueCredentialsException";
NSString *const SPInvalidCredentialsTokenException = @"SponsorPayInvalidCredentialsToken";


@interface SPCredentialsManager ()

@property (strong) NSMutableArray *credentialsItems;

@end


@implementation SPCredentialsManager

- (id)init
{
    self = [super init];
    if (self) {
        self.credentialsItems = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Credentials management

- (void)addCredentialsItem:(SPCredentials *)credentials forToken:(NSString *)token
{
    [self.credentialsItems addObject:credentials];
}

- (void)setCurrentCredentialsWithToken:(NSString *)credentialsToken
{
    // simply move credentials to last index
    SPCredentials *credentials = [self credentialsForToken:credentialsToken];
    if (credentials) {
        [self.credentialsItems removeObject:credentials];
        [self.credentialsItems addObject:credentials];
    } else {
        [self throwInvalidCredentialsTokenException];
    }
}

- (void)clearCredentials
{
    [self.credentialsItems removeAllObjects];
}

- (SPCredentials *)currentCredentials
{
    if ([self.credentialsItems count] < 1) {
        [self throwNoCredentialsException];
        return nil;
    } else {
        return [self.credentialsItems lastObject];
    }
}

- (SPCredentials *)credentialsForToken:(NSString *)credentialsToken
{
    SPCredentials *ret = nil;
    for (SPCredentials *c in self.credentialsItems) {
        if ([[c credentialsToken] isEqualToString:credentialsToken]) {
            ret = c;
        }
    }

    return ret;
}

#pragma mark - Credentials related exceptions

- (void)throwNoCredentialsException
{
    NSString *exceptionReason = @"Please start the SDK with "
                                 "[SponsorPaySDK startForAppId:userId:securityToken:] before accessing any of its resources";
    [NSException raise:SPNoCredentialsException format:@"%@", exceptionReason];
}

- (void)throwInvalidCredentialsTokenException
{
    NSString *exceptionReason = @"Please use [SponsorPaySDK startForAppId:userId:securityToken:] "
                                 "to obtain a valid credentials token. (No credentials found for the credentials token specified.)";
    [NSException raise:SPInvalidCredentialsTokenException format:@"%@", exceptionReason];
}

- (void)throwNoUniqueCredentialsException
{
    NSString *exceptionReason = @"More than one active SponsorPay appId / userId. Please use the credentials token "
                                 "to specify the appId / userId combination for which you're accessing the desired resource.";
    [NSException raise:SPNoUniqueCredentialsException format:@"%@", exceptionReason];
}


#pragma mark - Configuration per credentials item

- (SPCredentials *)setConfigurationValue:(id)value
                                  forKey:(NSString *)key
                  inCredentialsWithToken:(NSString *)token
{
    SPCredentials *credentials = [self credentialsForToken:token];
    credentials.userConfig[key] = value;
    return credentials;
}


- (void)setConfigurationValueInAllCredentials:(id)value
                                       forKey:(NSString *)key
{
    if (![self.credentialsItems count]) {
        NSString *exceptionReason = @"Please start the SDK with [SponsorPaySDK startForAppId:userId:securityToken:] before setting any of its configuration values.";
        [NSException raise:@"SponsorPaySDKNotStarted" format:@"%@", exceptionReason];
    } else {
        for (SPCredentials *c in self.credentialsItems) {
            c.userConfig[key] = value;
        }
    }
}

@end
