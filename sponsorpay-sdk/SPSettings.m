//
//  SPSDKSettings.m
//  SponsorPaySDK
//
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPSettings.h"

@implementation SPSettings

+ (instancetype) sharedInstance {
    static SPSettings *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[SPSettings alloc] init];
    });

    return __sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.enableLocalAdapterSettings = YES;
    }

    return self;
}


@end