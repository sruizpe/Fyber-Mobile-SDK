//
//  SPConfigurationRequestManager+Debug.h
//  SponsorPaySDK
//
//  Created by Piotr  on 02/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPConfigurationRequestManager.h"

@interface SPConfigurationRequestManager (Debug)

- (NSMutableArray *) overrideSettings:(NSMutableArray *)adapters;

- (id) mutableCopy:(id)object;

@end
