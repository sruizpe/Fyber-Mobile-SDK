//
//  SPSchemeParser.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 10/18/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPSchemeParser.h"
#import "SPConstants.h"
#import "SPLogger.h"
#import "NSString+SPAdditions.h"
#import "SPScheme.h"
#import "NSString+SPURLEncoding.h"
#import "NSURL+SPParametersParsing.h"


@interface SPSchemeParser ()

@end


@implementation SPSchemeParser

#pragma mark - Class Methods

+ (SPScheme *)parseUrl:(id)url
{
    // Check kindOfClass of url (NSURL|NSString)
    NSURL *URL;

    if ([url isKindOfClass:[NSURL class]]) {
        URL = url;
    } else if ([url isKindOfClass:[NSString class]]) {
        URL = [NSURL URLWithString:url];
    } else {
        SPLogError(@"The url parameter must be a NSString or a NSURL");
        return nil;
    }

    SPScheme *scheme = [[SPScheme alloc] init];
    scheme.urlScheme = [URL scheme];

    // Accept sponsorpay:// urls only
    if (![scheme isSponsorPayScheme]) {
        return scheme;
    }


    NSDictionary *parameters = [URL SPQueryDictionary];
    NSString *clickThroughURLString = [parameters[SPTPNClickThroughURL] SPURLDecodedString];

    scheme.clickThroughUrl = [NSURL URLWithString:clickThroughURLString];
    scheme.alertMessage = [parameters[SPTPNAlertMessageParameter] SPURLDecodedString];
    scheme.showAlert = [parameters[SPTPNShowAlertParameter] isEqualToString:@"true"];
    scheme.urlString =
    [[parameters[SPRequestURLParameterKey] SPURLDecodedString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    scheme.status = parameters[SPRequestStatusParameterKey];
    scheme.tpnName = parameters[SPThirtPartyNetworkParameter];
    scheme.numberOfOffers = [parameters[SPNumberOfOffersParameterKey] integerValue];
    scheme.tpnId = parameters[SPTPNIDParameter];

    if (scheme.tpnId) {
        scheme.contextData = @{ SPTPNIDParameter: scheme.tpnId };
    }

    [scheme setCommandTypeForUrl:URL];

    if (scheme.commandType == SPSchemeCommandTypeInstall) {
        scheme.appId = [parameters[SPRequestInstallAppId] SPURLDecodedString];
        scheme.affiliateToken = [parameters[SPRequestInstallAffiliateToken] SPURLDecodedString];
        scheme.campaignToken = [parameters[SPRequestInstallCampaignToken] SPURLDecodedString];
    }

    [scheme process];

    return scheme;
}

@end