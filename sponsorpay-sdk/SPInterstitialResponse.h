//
//  SPInterstitialResponseProcessor.h
//  SponsorPayTestApp
//
//  Created by David Davila on 27/10/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPInterstitialResponse : NSObject

@property (nonatomic, assign, readonly) BOOL isSuccessResponse;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, strong, readonly) NSArray *orderedOffers;

+ (instancetype)responseWithURLResponse:(NSURLResponse *)response data:(NSData *)data connectionError:(NSError *)connectionError;


@end
