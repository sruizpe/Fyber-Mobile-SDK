//
//  SPMockAlertViewVerifier.m
//  SponsorPayTestApp
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPMockAlertViewVerifier.h"
#import "SPMockAlertView.h"


@implementation SPMockAlertViewVerifier

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(alertShown:)
                                                     name:SPMockAlertViewShowNotification
                                                   object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)alertShown:(NSNotification *)notification {
    SPMockAlertView *alert = [notification object];
	++_showCount;
    
	self.title = alert.title;
	self.message = alert.message;
	self.delegate = alert.delegate;
	self.cancelButtonTitle = alert.cancelButtonTitle;
	self.otherButtonTitles = alert.otherButtonTitles;
}

@end
