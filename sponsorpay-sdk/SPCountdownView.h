//
//  SPCountdownView.h
//  testCountdownView
//
//  Created by Daniel Barden on 17/03/14.
//  Copyright (c) 2014 SponsorPay GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCountdownView : UIView

@property (nonatomic, strong) CAShapeLayer *innerCircleLayer;
@property (nonatomic, strong) CAShapeLayer *outerCircleLayer;
@property (nonatomic, strong) UILabel *countdownLabel;

/**
 The duration of the countdown view (in seconds)
 */
@property (nonatomic, assign) NSTimeInterval duration;

/**
 Plays or resumes the animation
 */
- (void)play;

/**
 Pauses the animation
 */
- (void)pause;

/**
 Updates the countdown timer. Used for resync the countdown when necessary

 @param timeInterval The new timeInterval for the countdown
 */
- (void)updateCountdownWithTimeInterval:(NSTimeInterval)timeInterval;

@end
