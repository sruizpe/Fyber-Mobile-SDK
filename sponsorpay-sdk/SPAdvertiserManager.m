//
//  SPAdvertiserManager.m
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <UIKit/UIDevice.h>
#import "SPAdvertiserManager.h"
#import "SPCallbackSendingOperation.h"
#import "SPURLGenerator.h"
#import "SPAppIdValidator.h"
#import "SPLogger.h"
#import "SPCredentials.h"
#import "SPPersistence.h"

static const NSInteger SPMaxConcurrentCallbackOperations = 1;
static NSOperationQueue *callbackOperationQueue = nil;

@interface SPAdvertiserManager ()

@property (strong) NSString *appId;

- initWithAppId:(NSString *)appId;
- (void)sendCallbackWithAction:(NSString *)actionId userId:(NSString *)userId;

@end

@implementation SPAdvertiserManager

#pragma mark - Initialization and deallocation

+ (SPAdvertiserManager *)advertiserManagerForAppId:(NSString *)appId
{
    static NSMutableDictionary *advertiserManagers;

    @synchronized(self)
    {
        if (!advertiserManagers) {
            advertiserManagers = [[NSMutableDictionary alloc] initWithCapacity:2];
        }

        if (!advertiserManagers[appId]) {
            SPAdvertiserManager *adManagerForThisAppId = [[self alloc] initWithAppId:appId];
            advertiserManagers[appId] = adManagerForThisAppId;
        }
    }

    return advertiserManagers[appId];
}

- (id)initWithAppId:(NSString *)appId
{
    self = [super init];

    if (self) {
        self.appId = appId;
    }

    return self;
}


#pragma mark - Advertiser callback delivery

- (void)reportOfferCompletedWithUserId:(NSString *)userId
{
    [SPAppIdValidator validateOrThrow:self.appId];
    [self sendCallbackWithAction:nil userId:userId];
}

- (void)reportActionCompleted:(NSString *)actionId
{
    [SPAppIdValidator validateOrThrow:self.appId];
    [self sendCallbackWithAction:actionId userId:nil];
}

- (void)sendCallbackWithAction:(NSString *)actionId userId:(NSString *)userId
{
    BOOL answerAlreadyReceived;
    void (^callbackSuccessfulCompletionBlock)();

    if (!actionId) {
        answerAlreadyReceived = [SPPersistence didAdvertiserCallbackSucceed];
        callbackSuccessfulCompletionBlock = ^{
            [SPPersistence setDidAdvertiserCallbackSucceed:YES];
        };
    } else {
        answerAlreadyReceived = [SPPersistence didActionCallbackSucceedForActionId:actionId];
        callbackSuccessfulCompletionBlock = ^{
            [SPPersistence setDidActionCallbackSucceed:YES
                                           forActionId:actionId];
        };
    }

    SPCredentials *credentials = [SPCredentials credentialsWithAppId:self.appId userId:userId securityToken:nil];

    SPCallbackSendingOperation *callbackOperation = [SPCallbackSendingOperation operationForCredentials:credentials
                                                                                               actionId:actionId
                                                                                         answerReceived:answerAlreadyReceived];

    callbackOperation.networkOperationSuccessBlock = callbackSuccessfulCompletionBlock;

    [self performCallbackSendingOperation:callbackOperation];
}

- (void)performCallbackSendingOperation:(SPCallbackSendingOperation *)callbackOperation
{
    SPLogDebug(@"%@ scheduling callback sending operation from thread:%@", self, [NSThread currentThread]);
    [[SPAdvertiserManager callbackOperationQueue] addOperation:callbackOperation];
}

#pragma mark -

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {appID = %@}", [super description], self.appId];
}

+ (NSOperationQueue *)callbackOperationQueue
{
    @synchronized(self)
    {
        if (!callbackOperationQueue) {
            callbackOperationQueue = [[NSOperationQueue alloc] init];
            [callbackOperationQueue setMaxConcurrentOperationCount:SPMaxConcurrentCallbackOperations];
        }
    }
    return callbackOperationQueue;
}

@end
