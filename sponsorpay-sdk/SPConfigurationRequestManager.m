//
//  SPConfigurationRequestManager.m
//  SponsorPaySDK
//
//  Created by Piotr on 6/17/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPConfigurationRequestManager.h"
#import "SPNetworkOperation.h"
#import "SPReachability.h"
#import "SPLogger.h"
#import "NSDictionary+SPSerialization.h"
#import "SPURLGenerator.h"
#import "SponsorPaySDK.h"
#import "SPCredentials.h"
#import "SPGlobalUtilities.h"
#import "SPSignature.h"
#import "SPConfigurationRequestManager+Debug.h"
#import "SPSettings.h"

static dispatch_queue_t jsonQueue;

NSString * const SPAdaptersFileName = @"SPAdapters.json";
NSString *const SPNetworkName = @"name";
NSString *const SPNetworks = @"adapters";
NSString *const SPNetworkParameters = @"settings";


typedef void (^SPConfigurationEnumerateSecretTokensBlock)(NSMutableDictionary *adapterSettings, NSMutableDictionary *adapter, NSString *key, NSString *keyWithoutPrefix);

@interface SPConfigurationRequestManager ()

@property (copy) SPConfigurationSuccessBlock configurationSuccessBlock;
@property (nonatomic, strong, readonly) SPCredentials *credentials;


@end

@implementation SPConfigurationRequestManager

#pragma mark - Lifecycle

- (id)initWithCredentials:(SPCredentials *)credentials completionBlock:(SPConfigurationSuccessBlock)completionBlock
{
    self = [super init];
    if (self) {
        _configurationSuccessBlock = completionBlock;
        _credentials = credentials;
    }
    return self;
}

- (id)init
{
    if ([self class] == [SPConfigurationRequestManager class]) {
        NSAssert(NO, @"Please use -initWithCredentials:completionBlock: instead");
        self = nil;
    } else {
        self = [super init];
    }
    
    return self;
}

#pragma mark - Public Methods

/* 
 There are 4 scenarios to handle
    1. Network is reachable and request from server is successful
    2. Network is reachable and request from server failed
    3. Network is not reachable but json file is available in cache directory ready to parse
    4. Network is not reachable and there is no json file in cache but plist file 
       is the only rescue - only if IGNORE_LOCAL_ADAPTERS_SETTINGS is undefined
 */

- (void)requestConfiguration
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        // If online request from server otherwise parse local cache

        if (![self isNetworkReachable]) {
            [self parseLocalFile];
            return;
        }

        SPLogDebug(@"Fetching JSON config file from server");
        SPNetworkOperation *operation = [[SPNetworkOperation alloc] initWithUrl:[self generateUrl]];
        operation.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

        operation.networkOperationFailedBlock = ^(SPNetworkOperation *networOperation, NSError *error) {
            self.operationFailedBlock(error); // Unfortunatelly we can't just pass self.configurationFailedBlock
        };
        // as we need to call fallback method to read local json in case
        // if the network response failed.
        operation.networkOperationSuccessBlock = ^(SPNetworkOperation *networkOperation){

            NSError *error = nil;
            if (![self signatureValid:networkOperation]) {
                NSString *errorDescription = @"Invalid response signature.";
                error = [[self class] errorWithdomain:@"sponsorpay.com" code:kCFSOCKS5ErrorNoAcceptableMethod description:errorDescription];

                if (self.operationFailedBlock) {
                    self.operationFailedBlock(error);
                }

                return;
            }

            // Convert data to json format
            NSData *data = [networkOperation.responseData copy];
            NSMutableDictionary *config = [[self class] json:data error:&error];
            NSMutableArray *adapters = config[SPNetworks];

            SPLogDebug(@"Received Server Side configuration");

            if (error || !adapters) {
                if (self.operationFailedBlock) {
                    self.operationFailedBlock(error);
                }
                return;
            }


            // Save json to cache
            [self saveJSON:adapters completionBlock:nil];


            if (self.shouldOverrideConfiguration) {
                // Override configuration
                NSMutableArray *delta = [self overrideSettings:adapters];
                if (delta) {
                    adapters = delta;
                }
            }

            if (self.configurationSuccessBlock) {
                self.configurationSuccessBlock(adapters);
            }
        };
        [operation start];
    });
}


#pragma mark - Private


- (BOOL)signatureValid:(__weak SPNetworkOperation *)operation
{
#ifdef ENABLE_STAGING
return YES;
#endif
    NSString *responseSignature = [operation.response allHeaderFields][@"X-Sponsorpay-Response-Signature"];
    NSString *responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
    BOOL isValid = [SPSignature isSignatureValid:responseSignature forText:responseString secretToken:self.credentials.securityToken];

    return isValid;
}

- (SPConfigurationFailedBlock)operationFailedBlock
{
    return ^(NSError *error) {
        // Notify the operation failed
        if (self.configurationFailedBlock) {
            self.configurationFailedBlock(error);
        }
        // Rescue call
        // Parse local json file in fallback
        SPLogDebug(@"Fallback action - parsing configuration from cached json file");
        [self parseLocalFile];
    };
}

- (void)parseLocalFile
{
    SPLogDebug(@"Reading local JSON config file");
    // File exists at provided path - parse
    // File doesn't exist at path - log error and parse the info from `...-Info.plist`
    NSString *filePath          = [[[self class] networksCachePath] stringByAppendingPathComponent:SPAdaptersFileName];
    NSMutableArray *adapters    = [[self class] jsonForFile:filePath];

    if (self.shouldOverrideConfiguration) {
        // Override configuration
        NSMutableArray *delta = [self overrideSettings:adapters];
        if (delta) {
            adapters = delta;
        }
    }

    if (!adapters || ![adapters count]) {
        // Log error
        NSString *errorDescription = @"Unable to parse information about available networks from local file. "
                                      "The local file may be absent, empty or corrupt. ";
        if (!self.shouldOverrideConfiguration) {
            errorDescription = [errorDescription stringByAppendingString:@"Connection to wifi or cellular carrier required."];
        } else {
            errorDescription = [errorDescription stringByAppendingString:@"Reading content from `...-Info.plist` file if available."];
        }
        NSError *error = [[self class] errorWithdomain:@"sponsorpay.com" code:-1005 description:errorDescription];
        if (self.configurationFailedBlock) {
            self.configurationFailedBlock(error);
        }

        if (self.shouldOverrideConfiguration) {
            // The last rescue is to get configuration from plist file
            [self adaptersFromPlist];
        }

        return;
    }

    // completion block should be called as data was finally provided
    if (self.configurationSuccessBlock) {
        self.configurationSuccessBlock(adapters);
    }
}


- (void)adaptersFromPlist
{
    if (!self.shouldOverrideConfiguration) return;

    // The last rescue is to get configuration from plist file
    SPLogDebug(@"Rescue action - parsing configuration from ...-Info.plist file");
    
    NSArray *adapters = [self parsePlistInfoDictionary];
    NSMutableArray *mutableAdapters = [self mutableCopy:adapters];

//    [self storeNetworkTokens:mutableAdapters];
    
    // completion block should be called as data was finally provided
    if (self.configurationSuccessBlock) {
        self.configurationSuccessBlock(mutableAdapters);
    }
}

- (id)parsePlistInfoDictionary
{
    id localAdapters = [[NSBundle mainBundle] infoDictionary][SPNetworks];
    if (!localAdapters || ![localAdapters count]) {
        SPLogWarn(@"Settings about the mediated networks could not be found in the info file");
        return nil;
    }
    return localAdapters;
}

- (NSURL *)generateUrl
{
    SPURLGenerator *urlGenerator = [[SPURLGenerator alloc] initWithEndpoint:SPURLEndpointAdaptersConfig];
    [urlGenerator setCredentials:self.credentials];
    return [urlGenerator signedURLWithSecretToken:self.credentials.securityToken];
}





- (BOOL)isNetworkReachable
{
    SPReachability *reachability = [SPReachability reachabilityForInternetConnection];
    SPNetworkStatus status = [reachability currentReachabilityStatus];
    return status != SPNetworkStatusNotReachable;
}

+ (NSString *)networksCachePath
{
	static NSString *_networksCachePath;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_networksCachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
		_networksCachePath = [_networksCachePath stringByAppendingPathComponent:@"SPNetworksCache"];

		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:_networksCachePath withIntermediateDirectories:YES attributes:nil error:&error];

		if (error) {
			SPLogError(@"Error: %@", error.description);
			_networksCachePath = nil;
		}
	});

	return _networksCachePath;
}

+ (dispatch_queue_t)jsonQueue
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		jsonQueue = dispatch_queue_create("savingJSONQueue", NULL);
	});

	return jsonQueue;
}

- (void)saveJSON:(NSMutableArray *)adapters completionBlock:(void(^)(BOOL success))completionBlock
{
    __block BOOL success;
    dispatch_async([[self class] jsonQueue], ^(void) {
        SPLogDebug(@"Caching JSON config data");
        NSError  *error      = nil;
		NSString *path       = [[[self class] networksCachePath] stringByAppendingPathComponent:SPAdaptersFileName];

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:adapters
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];

		success = [jsonData writeToFile:path options:NSDataWritingAtomic error:&error];

        if (error) {
            SPLogError(@"Error writing JSON file: %@", error.description);
        }
        if (completionBlock) {
            completionBlock(success);
        }
	});
}

/** 
 @note NSJSONSerialization takes NSJSONReadingMutableContainers option so it returns mutable object
 */
+ (id)json:(NSData *)data error:(NSError **)error
{
    NSMutableDictionary *config = [NSJSONSerialization JSONObjectWithData:data
                                            options:NSJSONReadingMutableContainers
                                              error:error];
    if (!config[SPNetworks]) {
        NSString *errorDescription = [NSString stringWithFormat:@"Invalid JSON. Expexted key '%@' in server side configuration response got %@", SPNetworks, config];
        *error = [[self class] errorWithdomain:@"sponsorpay.com" code:0 description:errorDescription];
        config = nil;
    }
    return config;
}

/**
 @note NSJSONSerialization takes NSJSONReadingMutableContainers option and it returns mutable object
 */
+ (id)jsonForFile:(NSString *)filePath
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:filePath];
        NSError *error = nil;
        id jsonObj = [[NSJSONSerialization JSONObjectWithData:fileData
                                                      options:NSJSONReadingMutableContainers
                                                        error:&error] copy];
        if (error) {
            SPLogError(@"Error while parsing file: %@", error.description);
            return nil;
        }
        return jsonObj;
	}
    return nil;

}

+ (NSError *)errorWithdomain:(NSString *)domain code:(NSInteger)code description:(NSString *)desc
{
	NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
	[errorDetails setValue:desc forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:domain code:code userInfo:errorDetails];
}

#pragma mark - Accessors

- (BOOL)shouldOverrideConfiguration
{
    return [SPSettings sharedInstance].enableLocalAdapterSettings;
}

@end
