//
//  SPCallbackSendingOperation.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 12/3/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPCallbackSendingOperation.h"
#import "SPURLGenerator.h"
#import "SPLogger.h"
#import "SPCredentials.h"

static NSString *const SPURLParamKeySuccessfulAnswerReceived = @"answer_received";
static NSString *const SPURLParameterKeyActionId = @"action_id";

@implementation SPCallbackSendingOperation

- (id)initWithCredentials:(SPCredentials *)credentials
                 actionId:(NSString *)actionId
           answerReceived:(BOOL)answerReceived
{
    NSURL *url = [[self class] callbackURLWithCredentials:credentials actionId:actionId answerReceived:answerReceived];
    self = [self initWithUrl:url];

    if (self) {
        self.credentials = credentials;
        self.actionId = actionId;
        self.answerAlreadyReceived = answerReceived;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {appId = %@ actionId = %@ answerAlreadyReceived = %d}", [super description], self.credentials.appId, self.actionId, self.answerAlreadyReceived];
}

+ (id)operationForCredentials:(SPCredentials *)credentials actionId:(NSString *)actionId answerReceived:(BOOL)answerReceived
{
    SPCallbackSendingOperation *operation = [[SPCallbackSendingOperation alloc] initWithCredentials:credentials
                                                                                           actionId:actionId
                                                                                     answerReceived:answerReceived];

    return operation;
}

#pragma mark - Private

+ (NSURL *)callbackURLWithCredentials:(SPCredentials *)credentials
                             actionId:(NSString *)actionId
                       answerReceived:(BOOL)answerReceived {

    SPURLEndpoint endpoint       = actionId ? SPURLEndPointActions : SPURLEndpointInstalls;
    SPURLGenerator *urlGenerator = [SPURLGenerator URLGeneratorWithEndpoint:endpoint];

    [urlGenerator setCredentials:credentials];
    [urlGenerator setParameterWithKey:SPURLParamKeySuccessfulAnswerReceived stringValue:answerReceived ? @"1" : @"0"];

    if ([actionId length]) {
        [urlGenerator setParameterWithKey:SPURLParameterKeyActionId stringValue:actionId];
    }

    return [urlGenerator generatedURL];
    
}

@end
