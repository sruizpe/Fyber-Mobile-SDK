//
//  SPSchemeParser.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 10/18/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPScheme;

@interface SPSchemeParser : NSObject

/**
 *  Parse a URL. Convient shortcut for [[SPSchemeParser sharedManager] parseUrl:url]
 *
 *  @param url URL to be parsed. Can be a NSURL or a NSString
 *
 *  @return a SPScheme object
 */
+ (SPScheme *)parseUrl:(id)url;

@end