//
//  NSURLRequest+UserAgent.h
//  SponsorPaySDK
//
//  Created by tito on 04/09/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (UserAgent)

+ (NSURLRequest *)requestSPUserAgentAndURL:(NSURL *)url;

@end
