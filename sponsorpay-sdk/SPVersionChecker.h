//
//  SPVersionChecker.h
//  SponsorPaySDK
//
//  Created by tito on 20/08/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SPFoundationVersionNumber [SPVersionChecker overridenVersion]

@interface SPVersionChecker : NSObject

+ (CGFloat)overridenVersion;
+ (void)setOverridenVersion:(NSString *)overridenVersion;

@end
