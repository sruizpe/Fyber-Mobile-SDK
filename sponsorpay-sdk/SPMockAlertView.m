//
//  SPMockAlertView.m
//  SponsorPayTestApp
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPMockAlertView.h"
#import <UIKit/UIKit.h>

NSString *const SPMockAlertViewShowNotification = @"SPMockAlertViewShowNotification";

@implementation SPMockAlertView

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    self = [super init];
    
    if (self) {
        _title = [title copy];
        _message = [message copy];
        _delegate = delegate;
        _cancelButtonTitle = [cancelButtonTitle copy];
        
        _otherButtonTitles = [[NSMutableArray alloc] init];
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *title = otherButtonTitles; title != nil; title = va_arg(args, NSString *)) {
            [_otherButtonTitles addObject:title];
        }
        va_end(args);
    }
    return self;
}


- (void)show {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPMockAlertViewShowNotification
                                                        object:self
                                                      userInfo:nil];
}

@end
