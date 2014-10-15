//
//  SPEventHub.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialEventHub.h"
#import "SPInterstitialEvent.h"
#import "SPNetworkOperation.h"
#import "SPURLGenerator.h"
#import "SPConstants.h"
#import "SPLogger.h"
#import "NSURL+SPDescription.h"

static const NSInteger SPMaxConcurrentOperations = 1;

@interface SPInterstitialEventHub ()

@property (nonatomic, strong) NSOperationQueue *networkQueue;
@property (nonatomic, copy) NSString *eventURL;

@end


@implementation SPInterstitialEventHub

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveInterstitialNotification:) name:SPInterstitialEventNotification object:nil];
        _networkQueue = [[NSOperationQueue alloc] init];
        _networkQueue.maxConcurrentOperationCount = SPMaxConcurrentOperations;
    }
    return self;
}

- (void)receiveInterstitialNotification:(NSNotification *)notification
{
    SPInterstitialEvent *event = (SPInterstitialEvent *)notification.object;
    if (![event isKindOfClass:[SPInterstitialEvent class]]) {
        [NSException raise:NSInvalidArgumentException format:@"%@", NSLocalizedString(@"Notification object is not of SPInterstitialEvent call", nil)];
    }

    SPURLGenerator *url = [SPURLGenerator URLGeneratorWithEndpoint:SPURLEndpointTracker];
    [url setCredentials:self.credentials];

    [url addParametersProvider:event];
    SPNetworkOperation *networkOp = [[SPNetworkOperation alloc] initWithUrl:[url generatedURL]];

    networkOp.networkOperationSuccessBlock = ^(SPNetworkOperation *operation){
        SPLogDebug(@"Did send callback using url and query string: %@", [operation.url SPPrettyDescription]);

        SPLogDebug(@"Operation return with status: %d", operation.response.statusCode);
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:operation.response.allHeaderFields forURL:operation.url];
        SPLogDebug(@"Number of cookies returned %d", [cookies count]);
        [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie *obj, NSUInteger idx, BOOL *stop) {
            SPLogDebug(@"Name: %@\nValue: %@", obj.name, obj.value);
        }];
    };

    [networkOp start];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_networkQueue cancelAllOperations];
}

@end
