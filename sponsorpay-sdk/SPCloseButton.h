//
//  SPCloseButton.h
//  SPVideoPlayer
//
//  Created by Daniel Barden on 29/01/14.
//  Copyright (c) 2014 SponsorPay GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCloseButton : UIButton

@property (nonatomic, assign, readonly) UIEdgeInsets paddingInsets;

- (id)initWithFrame:(CGRect)frame paddingInsets:(UIEdgeInsets)insets;

@end
