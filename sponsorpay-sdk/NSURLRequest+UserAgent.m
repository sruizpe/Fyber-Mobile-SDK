//
//  NSURLRequest+UserAgent.m
//  SponsorPaySDK
//
//  Created by tito on 04/09/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "NSURLRequest+UserAgent.h"
#import <UIKit/UIKit.h>

@implementation NSURLRequest (UserAgent)

+ (NSURLRequest *)requestSPUserAgentAndURL:(NSURL *)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    NSString *userAgent = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];

    [request addValue:userAgent forHTTPHeaderField:@"User-Agent"];

    return request;
}

@end
