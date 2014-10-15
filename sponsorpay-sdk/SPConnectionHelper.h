//
//  ConnectionHelper.h
//  SponsorPaySDK
//
//  Created by tito on 08/09/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPConnectionHelper : NSObject

+ (instancetype)sharedInstance;

- (void)checkConnectivityWithFailure:(void (^)(void))failureBlock;

@end
