//
//  SPOrientationHelper.h
//  SponsorPayTestApp
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SPOrientationHelper : NSObject

/**
 *  Returns the device's current orientation
 *
 *  @return The current orientation (UIInterfaceOrientation) of the device
 */
+ (UIInterfaceOrientation)currentStatusBarOrientation;


/**
 *  Returns a CGRect that is calculated based on orientation
 *
 *  @param interfaceOrientation The orientation of the device
 *
 *  @return A CGRect frame
 */
+ (CGRect)fullScreenFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end
