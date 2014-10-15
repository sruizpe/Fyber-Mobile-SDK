//
//  SPSDKSettings.h
//  SponsorPaySDK
//
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

///----------------
/// Global SDK settings
///----------------

#import <Foundation/Foundation.h>

@interface SPSettings : NSObject

/**
 Request the shared instance of the current class.

 @return Returns restricted instance of the current class
 */
+ (instancetype) sharedInstance;

/**
 Indicates whether configuration included in info Dictionary of `...-Info.plist` file should override settings passsed from remote request.

 @note It also provides configuration fallback in case there is no data passed from server or local 'json' file is not available
 */
@property (assign) BOOL enableLocalAdapterSettings;

@end