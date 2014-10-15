//
//  ConnectionHelper.m
//  SponsorPaySDK
//
//  Created by tito on 08/09/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPConnectionHelper.h"

@implementation SPConnectionHelper

+ (instancetype)sharedInstance
{
    static SPConnectionHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^( void ) {
        sharedInstance = [[SPConnectionHelper alloc] init];
    });

    return sharedInstance;
}

- (void)checkConnectivityWithFailure:(void (^)(void))failureBlock {
    NSURL *fyberURL = [NSURL URLWithString:@"http://www.fyber.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fyberURL];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError && failureBlock) {
            failureBlock();
        }
    }];
}

@end
