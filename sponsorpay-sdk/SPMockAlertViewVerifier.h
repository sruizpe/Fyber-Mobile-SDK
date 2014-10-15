//
//  SPMockAlertViewVerifier.h
//  SponsorPayTestApp
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPMockAlertViewVerifier : NSObject

@property (nonatomic, assign) NSUInteger showCount;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) id delegate;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, copy) NSArray *otherButtonTitles;

- (id)init;

@end
