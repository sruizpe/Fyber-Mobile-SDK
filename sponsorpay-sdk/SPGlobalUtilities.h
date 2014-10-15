//
//  SPGlobalUtilities.h
//  SponsorPaySDK
//
//  Created by Piotr  on 30/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

///---------------------------------------------------------------------------------------------
/// @note This class contains mainly class methods. It provides request for app and device related data
///---------------------------------------------------------------------------------------------

@interface SPGlobalUtilities : NSObject

/**
 Allocation method prevents from class being initialised
 */
+ (id)alloc;

/**
 Obtains current app bundle identifier
 */
+ (NSString *) bundleIdentifier;

@end
