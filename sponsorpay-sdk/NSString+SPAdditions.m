//
//  NSString+SPAdditions.m
//  SponsorPaySDK
//
//  Created by Titouan on 17/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "NSString+SPAdditions.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(NSString_SPAdditions)

@implementation NSString (SPAdditions)

+ (BOOL)isStringEmpty:(NSString *)string
{
    return string == nil || [string isEqualToString:@""];
}

@end