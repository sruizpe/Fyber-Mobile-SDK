//
//  SPScheme.h
//  SponsorPaySDK
//
//  Created by Titouan on 18/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SPSchemeCommandType) {
    SPSchemeCommandTypeNone,
    SPSchemeCommandTypeRequestOffers,
    SPSchemeCommandTypeStart,
    SPSchemeCommandTypeExit,
    SPSchemeCommandTypeInstall,
    SPSchemeCommandTypeValidate,
    SPSchemeCommandTypePlayLocal,
    SPSchemeCommandTypePlayTPN
};

@interface SPScheme : NSObject

@property (nonatomic, strong) NSDictionary *contextData;

/**
 *  The scheme of the parsed URL (e.g @"sponsorpay")
 */
@property (nonatomic, copy) NSString *urlScheme;

/**
 *  The value associated to the SKStoreProductParameterITunesItemIdentifier in the parameters passed to the SKStoreProductViewController
 */
@property (nonatomic, copy) NSString *appId;

/**
 *  The value associated to the SKStoreProductParameterAffiliateToken in the parameters passed to the SKStoreProductViewController
 */
@property (nonatomic, copy) NSString *affiliateToken;

/**
 *  The value associated to the SKStoreProductParameterCampaignToken in the parameters passed to the SKStoreProductViewController
 */
@property (nonatomic, copy) NSString *campaignToken;

/**
 *  'status' parameter contained in the parsed url
 */
@property (nonatomic, copy) NSString *status;

/**
 *  The name of the Third Party Provider (e.g AppLovin)
 */
@property (nonatomic, copy) NSString *tpnName;

/**
 *  The Id of the Third Party Provider
 */
@property (nonatomic, copy) NSString *tpnId;

/**
 *  'url' parameter contained in the parsed url
 */
@property (nonatomic, copy) NSURL *externalDestination;
@property (nonatomic, copy) NSString *urlString;

/**
 *  Is actually a boolean (true/false). Used to display an alert if the user tries
 *  to close an Rewarded Video
 */
@property (nonatomic, assign) BOOL showAlert;

/**
 *  The message to show in the alert
 */
@property (nonatomic, copy) NSString *alertMessage;

/**
 *  URL to open when the user taps on (some) Rewarded Video
 */
@property (nonatomic, copy) NSURL *clickThroughUrl;

/**
 *  The type of the command (e.g: SPSchemeCommandTypeStart)
 */
@property (nonatomic, assign) SPSchemeCommandType commandType;

/**
 *  The number of offers returned
 */
@property (nonatomic, assign) NSInteger numberOfOffers;

/**
 *  If set to YES, this View Controller will be automatically dismissed when the user clicks on an offer and is
 * redirected outside the app.
 */
@property (nonatomic, assign) BOOL shouldRequestCloseWhenOpeningExternalURL;

/**
 *  Gets its value later from shouldRequestCloseWhenOpeningExternalURL
 */
@property (nonatomic, assign) BOOL requestsClosing;

/**
 *  Is set to YES if a valid external URL is found in the parsed URL. Then openURL is called
 */
@property (nonatomic, assign) BOOL requestsOpeningExternalDestination;

/**
 *  0 = open; 1 = close;
 */
@property (nonatomic, assign) NSInteger closeStatus;


#pragma mark - Helpers

/**
 *  Set some flags to the right value
 */
- (void)process;

/**
 *  Convienient helper to check if the scheme of the parsed URL is @"sponsorpay"
 *
 *  @return YES or NO
 */
- (BOOL)isSponsorPayScheme;


/**
 *  Set the command type of the scheme
 *
 *  @param url
 */
- (void)setCommandTypeForUrl:(NSURL *)url;

@end
