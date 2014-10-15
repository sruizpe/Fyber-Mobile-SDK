//
//  SPScreenMetricsProvider.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 11/2/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPScreenMetricsProvider.h"

static NSString *const URL_PARAM_SCREEN_WIDTH = @"screen_width";
static NSString *const URL_PARAM_SCREEN_HEIGHT = @"screen_height";

@implementation SPScreenMetricsProvider

- (NSDictionary *)dictionaryWithKeyValueParameters
{
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGFloat screenScale = [mainScreen scale] ? mainScreen.scale : 1.0;
    NSInteger actualScreenWidth = round(mainScreen.bounds.size.width * screenScale);
    NSInteger actualScreenHeight = round(mainScreen.bounds.size.height * screenScale);

    NSDictionary *screenMetrics = @{
        URL_PARAM_SCREEN_WIDTH: [NSString stringWithFormat:@"%ld", (long)actualScreenWidth],
        URL_PARAM_SCREEN_HEIGHT: [NSString stringWithFormat:@"%ld", (long)actualScreenHeight]
    };

    return screenMetrics;
}

@end
