//
//  SPOrientationHelper.m
//  SponsorPayTestApp
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPOrientationHelper.h"

@implementation SPOrientationHelper

#pragma mark - Class Methods

+ (UIInterfaceOrientation)currentStatusBarOrientation
{
    return [[UIApplication sharedApplication] statusBarOrientation];
}


+ (CGRect)fullScreenFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGRect applicationFrame = [[UIScreen mainScreen] bounds];
    CGRect fullScreenFrame;

    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        fullScreenFrame = applicationFrame;
    } else {
        fullScreenFrame =
        CGRectMake(applicationFrame.origin.y, applicationFrame.origin.x, applicationFrame.size.height, applicationFrame.size.width);
    }

    return fullScreenFrame;
}

@end
