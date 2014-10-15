//
//  SPConstants.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 08/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPConstants.h"

@implementation SPConstants

// Interstitial Event Notification constants
NSString *const SPInterstitialEventNotification = @"SPInterstitialEventNotification";

// Url Generator Constants
NSString *const SPUrlGeneratorRequestIDKey = @"request_id";

// Exceptions Names

NSString *const SPInvalidUserIdException = @"SPInvalidUserIdException";

// VCS
NSString *const SPCurrencyNameChangeNotification = @"SPCurrencyNameChangeNotification";
NSString *const SPNewCurrencyNameKey = @"SPNewCurrencyNameKey";

// SPSchemeParser

NSString *const SPCustomURLScheme = @"sponsorpay";

NSString *const SPRequestOffersAnswer = @"requestOffers";
NSString *const SPRequestInstall = @"install";
NSString *const SPRequestExit = @"exit";
NSString *const SPRequestValidate = @"validate";
NSString *const SPRequestPlay = @"play";
NSString *const SPRequestStartStatus = @"start";

NSString *const SPRequestInstallAppId = @"id";
NSString *const SPRequestInstallAffiliateToken = @"affiliateToken";
NSString *const SPRequestInstallCampaignToken = @"campaignToken";
NSString *const SPRequestURLParameterKey = @"url";
NSString *const SPRequestStatusParameterKey = @"status";
NSString *const SPThirtPartyNetworkParameter = @"tpn";
NSString *const SPNumberOfOffersParameterKey = @"n";

NSString *const SPTPNLocalName = @"local";
NSString *const SPTPNShowAlertParameter = @"showAlert";
NSString *const SPTPNAlertMessageParameter = @"alertMessage";
NSString *const SPTPNClickThroughURL = @"clickThroughUrl";
NSString *const SPTPNIDParameter = @"id";
@end
