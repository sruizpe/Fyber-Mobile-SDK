//
//  SPVersionChecker.m
//  SponsorPaySDK
//
//  Created by tito on 20/08/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPVersionChecker.h"
#import "SPLogger.h"

#ifndef NSFoundationVersionNumber_iOS_7_0
#define NSFoundationVersionNumber_iOS_7_0 1047.20
#endif

#ifndef NSFoundationVersionNumber_iOS_7_1
#define NSFoundationVersionNumber_iOS_7_1 1047.25
#endif

#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_iOS_8_0 1134.10
#endif

@implementation SPVersionChecker

static NSNumber *_overridenVersion;

static NSDictionary *_versions;

+ (void)initialize
{
    if (self == [SPVersionChecker class]) {
        _versions = @{@"4.3": @(NSFoundationVersionNumber_iOS_4_3),
                      @"5.0": @(NSFoundationVersionNumber_iOS_5_0),
                      @"5.1": @(NSFoundationVersionNumber_iOS_5_1),
                      @"6.0": @(NSFoundationVersionNumber_iOS_6_0),
                      @"6.1": @(NSFoundationVersionNumber_iOS_6_1),
                      @"7.0": @(NSFoundationVersionNumber_iOS_7_0),
                      @"7.1": @(NSFoundationVersionNumber_iOS_7_1),
                      @"8.0": @(NSFoundationVersionNumber_iOS_8_0)};
    }
}


+ (CGFloat)overridenVersion
{
    @synchronized(self)
    {
        if (!_overridenVersion) {
            return NSFoundationVersionNumber;
        }

        return [_overridenVersion floatValue];
    }
}


+ (void)setOverridenVersion:(NSString *)overridenVersion
{
    @synchronized(self)
    {

        if (!_versions[overridenVersion]) {
            SPLogDebug(@"OS Version is not overriden");
            _overridenVersion = nil;
            return;
        }

        SPLogDebug(@"Settings Overriden Version: %@", overridenVersion);
        _overridenVersion = _versions[overridenVersion];
    }
}

@end
