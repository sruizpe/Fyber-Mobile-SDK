//
//  SPNetworkOperation.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 11/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPNetworkOperation.h"
#import "SPURLGenerator.h"
#import "SPLogger.h"

static const NSTimeInterval SPCallbackOperationTimeout = 60.0;

@interface SPNetworkOperation () <NSURLConnectionDelegate>

@property (nonatomic, strong, readwrite) NSURLConnection *connection;
@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong, readwrite) NSMutableData *responseData;
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;

@end

@implementation SPNetworkOperation

#if OS_OBJECT_HAVE_OBJC_SUPPORT
#else
@synthesize completionQueue = _completionQueue;

- (void)setCompletionQueue:(dispatch_queue_t)completionQueue
{
    if (completionQueue == _completionQueue) {
        return;
    }

    if (_completionQueue) {
        dispatch_release(_completionQueue);
    }

    _completionQueue = completionQueue;
    dispatch_retain(_completionQueue);
}
#endif

+ (void)networkRequestThreadEntryPoint
{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"SPNetworking"];

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint) object:nil];
        [_networkRequestThread start];
    });

    return _networkRequestThread;
}

- (id)initWithUrl:(NSURL *)url {
    self = [self init];
    if (self) {
        _url = url;
    }
    return self;
}

- (void)dealloc
{
#if OS_OBJECT_HAVE_OBJC_SUPPORT
#else
    if (_completionQueue){
        dispatch_release(_completionQueue);
    }
#endif
}
#pragma mark - Private

- (BOOL)isConcurrent {
    return YES;
}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    [self performSelector:@selector(startRequest) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO];
}

- (void)startRequest {
    if ([self performCancel]) {
        return;
    }

    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:self.url
                                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                            timeoutInterval:SPCallbackOperationTimeout];

    [self.headerParameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [request addValue:value forHTTPHeaderField:key];
    }];

    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection start];
}

- (BOOL)performCancel {
	if ([self isCancelled]){
		[self finish];
		return YES;
	}
	return NO;
}

- (void)finish {
    [self.connection cancel];

    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];

    _isExecuting = NO;
    _isFinished = YES;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Accessors
- (NSMutableData *)responseData {
    if (!_responseData) {
        _responseData = [[NSMutableData alloc] init];
    }
    return _responseData;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    SPLogDebug(@"Received configuration request response");
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.response = (NSHTTPURLResponse*)response;
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    if ([self performCancel]) {
        return;
    }
    SPLogDebug(@"Received request data");
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    SPLogError(@"Loading failed with error: %@", error.description);

    if (self.networkOperationFailedBlock) {
        dispatch_queue_t queue = self.completionQueue ? self.completionQueue : dispatch_get_main_queue();
        dispatch_sync(queue, ^{
            self.networkOperationFailedBlock(self, error);
        });
    }
    [self finish];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    SPLogDebug(@"Finished loading request");

    if (self.networkOperationSuccessBlock) {
        dispatch_queue_t queue = self.completionQueue ? self.completionQueue : dispatch_get_main_queue();
        dispatch_sync(queue, ^{
            self.networkOperationSuccessBlock(self);
        });
    }
    [self finish];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

@end
