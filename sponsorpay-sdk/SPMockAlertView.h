//
//  SPMockAlertView.h
//  SponsorPayTestApp
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

extern NSString *const SPMockAlertViewShowNotification;

@interface SPMockAlertView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, weak) id delegate;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, strong) NSMutableArray *otherButtonTitles;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
- (void)show;

@end
