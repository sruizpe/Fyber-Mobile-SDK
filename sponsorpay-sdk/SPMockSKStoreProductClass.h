//
//  SPMockSKStoreProductClass.h
//  SponsorPaySDK
//
//  Created by Titouan on 23/06/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionBlock)(BOOL result, NSError *error);

@interface SPMockSKStoreProductClass : NSObject

@property (strong, nonatomic) NSDictionary *parameters;
@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, weak) id delegate;

- (void)loadProductWithParameters:(NSDictionary *)parameters completionBlock:(CompletionBlock)block __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_6_0);

@end
