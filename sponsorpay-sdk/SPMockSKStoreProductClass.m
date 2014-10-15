//
//  SPMockSKStoreProductClass.m
//  SponsorPaySDK
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPMockSKStoreProductClass.h"

@implementation SPMockSKStoreProductClass

- (void)loadProductWithParameters:(NSDictionary *)parameters completionBlock:(CompletionBlock)block __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_6_0) {
    _parameters = [parameters copy];
    
    if (block) {
        NSString *localizedDescription = @"This is a localized description";
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:localizedDescription forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [[NSError alloc] initWithDomain:@"Error" code:400 userInfo:userInfo];
        
        block(YES, error);
    }
}

@end
