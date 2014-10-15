//
//  SPNetworkOperation.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 11/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPNetworkOperation;
typedef void (^SPNetworkOperationFailedBlock)(SPNetworkOperation *, NSError *);
typedef void (^SPNetworkOperationSuccessBlock)(SPNetworkOperation *);

@interface SPNetworkOperation : NSOperation {
	BOOL _isFinished;
    BOOL _isExecuting;
}

@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, strong, readonly) NSMutableData *responseData;
@property (nonatomic, strong, readonly) NSURL *url;

/**
 Collection of header parameters
 */
@property (nonatomic, strong) NSDictionary *headerParameters;

/**
 Block for handling failed request. This block property is called when remote network operation fails.
 This block takes one argument `error`.
 This block will be called on the main thread.
 */
@property (nonatomic, copy) SPNetworkOperationFailedBlock  networkOperationFailedBlock;

/**
 Block for handling success request. This block property is called when remote network operation succeeded.
 This block will be called on the main thread.
 */
@property (nonatomic, copy) SPNetworkOperationSuccessBlock  networkOperationSuccessBlock;

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
#if OS_OBJECT_HAVE_OBJC_SUPPORT
@property (nonatomic, strong) dispatch_queue_t completionQueue;
#else
@property (nonatomic, assign) dispatch_queue_t completionQueue;
#endif

/**
 Initializes an `SPNetworkOperation` object with the specified URL.

 @param url The URL for the HTTP call.
 */
- (id) initWithUrl:(NSURL *)url;

@end
