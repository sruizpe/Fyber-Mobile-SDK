//
//  SPGlobalUtilities.m
//  SponsorPaySDK
//
//  Created by Piotr  on 30/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPGlobalUtilities.h"

@implementation SPGlobalUtilities

#pragma mark - Life cycyle

+(id)alloc {
    NSAssert(NO, @"This class cannot be instantiated!");
    return nil;
}

#pragma mark - Public class methods

+ (NSString *) bundleIdentifier {
    static NSString *_bundleIdentifier;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        _bundleIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    });
    return _bundleIdentifier;
}

@end
