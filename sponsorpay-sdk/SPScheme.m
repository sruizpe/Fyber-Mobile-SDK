//
//  SPScheme.m
//  SponsorPaySDK
//
//  Created by Titouan on 18/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPScheme.h"
#import "SPConstants.h"
#import "NSString+SPAdditions.h"

@implementation SPScheme

- (id)init
{
    self = [super init];

    if (self) {
        self.requestsOpeningExternalDestination = NO;
        self.requestsClosing = NO;
        self.closeStatus = 0;

        self.commandType = SPSchemeCommandTypeNone;
    }

    return self;
}

- (void)process
{
    switch (self.commandType) {
    case SPSchemeCommandTypeInstall:
        self.requestsClosing = self.shouldRequestCloseWhenOpeningExternalURL;
        break;

    case SPSchemeCommandTypeExit: {
        BOOL isDestinationEmpty = [NSString isStringEmpty:self.urlString];

        if (isDestinationEmpty) {
            self.requestsClosing = YES;
        } else {
            self.externalDestination = [[NSURL alloc] initWithString:self.urlString];
            self.requestsOpeningExternalDestination = YES;
            self.requestsClosing = self.shouldRequestCloseWhenOpeningExternalURL;
        }

        if (self.requestsClosing) {
            self.closeStatus = [self.status integerValue];
        }

        break;
    }

    default:
        break;
    }
}


#pragma mark - Customize Setter Methods

- (void)setShouldRequestCloseWhenOpeningExternalURL:(BOOL)shouldRequestCloseWhenOpeningExternalURL
{
    _shouldRequestCloseWhenOpeningExternalURL = shouldRequestCloseWhenOpeningExternalURL;
    [self process];
}

#pragma mark - Helpers

- (BOOL)isSponsorPayScheme
{
    return [self.urlScheme isEqualToString:SPCustomURLScheme];
}


- (void)setCommandTypeForUrl:(NSURL *)url
{
    NSString *command = [url host];

    if ([command isEqualToString:SPRequestOffersAnswer]) {
        self.commandType = SPSchemeCommandTypeRequestOffers;
    } else if ([command isEqualToString:SPRequestStartStatus]) {
        self.commandType = SPSchemeCommandTypeStart;
    } else if ([command isEqualToString:SPRequestExit]) {
        self.commandType = SPSchemeCommandTypeExit;
    } else if ([command isEqualToString:SPRequestValidate]) {
        self.commandType = SPSchemeCommandTypeValidate;
    } else if ([command isEqualToString:SPRequestPlay]) {
        if ([self.tpnName isEqualToString:SPTPNLocalName]) {
            self.commandType = SPSchemeCommandTypePlayLocal;
        } else {
            self.commandType = SPSchemeCommandTypePlayTPN;
        }
    } else if ([command isEqualToString:SPRequestInstall]) {
        self.commandType = SPSchemeCommandTypeInstall;
    }
}

@end