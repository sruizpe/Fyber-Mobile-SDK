//
//  SPCallbackSendingOperation.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 12/3/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPNetworkOperation.h"

@class SPCredentials;

@interface SPCallbackSendingOperation : SPNetworkOperation

@property (nonatomic, strong) SPCredentials *credentials;
@property (strong) NSString *actionId;

@property (assign) BOOL answerAlreadyReceived;

- (id)initWithCredentials:(SPCredentials *)credentials
                 actionId:(NSString *)actionId
           answerReceived:(BOOL)answerReceived;

+ (id)operationForCredentials:(SPCredentials *)credentials
                     actionId:(NSString *)actionId
               answerReceived:(BOOL)answerReceived;

@end
