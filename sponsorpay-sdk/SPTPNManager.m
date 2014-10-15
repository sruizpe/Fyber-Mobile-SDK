//
//  SPProviderManager.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 30/12/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPBaseNetwork.h"
#import "SPTPNManager.h"
#import "SPLogger.h"
#import "SPSemanticVersion.h"
#import "SPConfigurationRequestManager.h"
#import "SPCredentials.h"
#import "SPVersionChecker.h"

typedef void (^SPNetworkCompletionBlock)(NSArray *networks);



static const NSInteger SPAdapterSupportedVersion = 3;

@interface SPTPNManager ()

@property (nonatomic, strong) NSMutableDictionary *networks;

@end

@implementation SPTPNManager

#pragma mark - Class methods
+ (instancetype)sharedInstance
{
    static SPTPNManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedInstance = [[SPTPNManager alloc] init]; });
    return sharedInstance;
}

+ (void)startNetworksWithCredentials:(SPCredentials *)credentials
{
    [[self sharedInstance] startNetworksWithCredentials:(SPCredentials *)credentials];
}

+ (id<SPTPNVideoAdapter>)getRewardedVideoAdapterForNetwork:(NSString *)networkName
{
    return [[self sharedInstance] getRewardedVideoAdapterForNetwork:networkName];
}

+ (NSArray *)getAllRewardedVideoAdapters
{
    return [[self sharedInstance] getAllRewardedVideoAdapters];
}

+ (id<SPInterstitialNetworkAdapter>)getInterstitialAdapterForNetwork:(NSString *)networkName
{
    return [[self sharedInstance] getInterstitialAdapterForNetwork:networkName];
}

+ (NSArray *)getAllInterstitialAdapters
{
    return [[self sharedInstance] getAllInterstitialAdapters];
}

#pragma mark - Lifecycle
- (id)init
{
    self = [super init];
    if (self) {
        _networks = [[NSMutableDictionary alloc] init];
    }
    return self;
}



- (SPNetworkCompletionBlock) networkCompletionBlock {
    return ^void(NSArray *networks) {
        [networks enumerateObjectsUsingBlock:^(id providerData, NSUInteger idx, BOOL *stop) {
            NSString *networkName = providerData[SPNetworkName];


            Class NetworkClass = [self getValidClassForNetwork:networkName];

            if (!NetworkClass) {
                return;
            }


            SPBaseNetwork *network = [self getNetworkWithClass:NetworkClass];
            if (!network) {
                network = (SPBaseNetwork *) [[NetworkClass alloc] init];
            }

            // Starts the SDK and Adapters

            BOOL sdkStarted = [network startNetworkWithName:networkName data:providerData[SPNetworkParameters]];
            
            if (!sdkStarted) {
                [self.networks removeObjectForKey:[network.name lowercaseString]];
                return;
            }

            (self.networks)[[network.name lowercaseString]] = network;
        }];
    };
}

- (void)startNetworksWithCredentials:(SPCredentials *)credentials
{
    if (SPFoundationVersionNumber < NSFoundationVersionNumber_iOS_5_0) {
               SPLogError(@"The device is running a version of iOS (%f) that is inferior to the lowest iOS version (%f) "
                          @"compatible with Fyber's SDK",
                          SPFoundationVersionNumber,
                          NSFoundationVersionNumber_iOS_5_0);
        SPLogInfo(@"Network adapters will not be started");
        return;
    }

    // Add configuration request from server side
    SPConfigurationRequestManager *configManager = [[SPConfigurationRequestManager alloc] initWithCredentials:credentials completionBlock:[self networkCompletionBlock]];
    configManager.configurationFailedBlock = ^void(NSError *error) {
        SPLogError(@"%@", [error localizedDescription]);
    };
    [configManager requestConfiguration];
}

- (id<SPTPNVideoAdapter>)getRewardedVideoAdapterForNetwork:(NSString *)networkName
{
    SPBaseNetwork *network = self.networks[[networkName lowercaseString]];
    if (network.supportedServices & SPNetworkSupportRewardedVideo) {
        return [network rewardedVideoAdapter];
    } else {
        return nil;
    }
}

- (NSArray *)getAllRewardedVideoAdapters
{
    __block NSMutableArray *videoAdapters = [[NSMutableArray alloc] init];
    NSArray *networks = [self.networks allValues];
    [networks enumerateObjectsUsingBlock:^(SPBaseNetwork *network, NSUInteger idx, BOOL *stop) {
    if ([network supportedServices] & SPNetworkSupportRewardedVideo) {
        [videoAdapters addObject:[network rewardedVideoAdapter]];
    }
    }];
    return [NSArray arrayWithArray:videoAdapters];
}

- (id<SPInterstitialNetworkAdapter>)getInterstitialAdapterForNetwork:(NSString *)networkName
{
    SPBaseNetwork *network = self.networks[[networkName lowercaseString]];

    if (network.supportedServices & SPNetworkSupportInterstitial) {
        return [network interstitialAdapter];
    } else {
        return nil;
    }
}

- (NSArray *)getAllInterstitialAdapters
{
    __block NSMutableArray *interstitialAdapters = [[NSMutableArray alloc] init];
    NSArray *networks = [self.networks allValues];
    [networks enumerateObjectsUsingBlock:^(SPBaseNetwork *network, NSUInteger idx, BOOL *stop) {
    if ([network supportedServices] & SPNetworkSupportInterstitial) {
        [interstitialAdapters addObject:[network interstitialAdapter]];
    }
    }];
    return [NSArray arrayWithArray:interstitialAdapters];
}

#pragma mark - Helper Methods

- (SPBaseNetwork *)getNetworkWithClass:(__unsafe_unretained Class)networkClass
{
    // Checks if the provider is already integrated. Since we won't reuse networks, we can check if an object of the
    // network class exists in the networks
    // Also, sometimes the provider.name is different than suffix used to instantiate the class
    NSArray *integratedNetworks = [self.networks allValues];
    NSUInteger index = [integratedNetworks indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj class] == networkClass) {
        *stop = YES;
        return YES;
    }
    return NO;
    }];

    if (index == NSNotFound) {
        return nil;
    } else {
        return integratedNetworks[index];
    }
}

// The adapter's major version reflects the version of the interface between the sdk <-> adapter.
// TODO remove for 7.0.0 - SPAdapterOlderSupportedVersion and tests based on it
static const NSInteger SPAdapterOlderSupportedVersion = 2;
- (BOOL)isAdapterVersionValid:(SPSemanticVersion *)adapterVersion
{
    return adapterVersion.major == SPAdapterSupportedVersion || adapterVersion.major == SPAdapterOlderSupportedVersion;
}


/**
 *  Returns a valid network class class for the supplied network name. Used for backward compatibility with 2.0 Adapters
 *  with different class names
 *
 *  @param networkName The name of the network as it comes for the server side configuration
 *
 *  @return nil or the class that checked that it
 *      - exists
 *      - is a subclass of SPBaseNetwork
 *      - isAdapterVersionValid
 */
- (Class)getValidClassForNetwork:(NSString *)networkName
{

    // Mapping used for Networks whose class name does not match SP+Name+Network pattern
    static NSDictionary *networkNameToClassMapping;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        networkNameToClassMapping = @{
                @"HyprMx" : @[ @"SPHyprMXNetwork" ],
                @"Inmobi" : @[ @"SPInMobiNetwork", @"SPInmobiNetwork" ], // 2.0 SPInMobiNetwork 3.0 SPInmobiNetwork
                @"FlurryAppCircleClips" : @[ @"SPFlurryNetwork", @"SPFlurryAppCircleClipsNetwork" ], // 2.0 SPFlurryNetwork 3.0 SPFlurryAppCircleClipsNetwork
                @"Inmobi" : @[ @"SPInMobiNetwork", @"SPInmobiNetwork" ] // 2.0 SPInMobiNetwork 3.0 SPInmobiNetwork
        };
    });

    __block Class foundNetworkClass;


    NSString *trimmedNetworkName = [networkName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    // add the "SP+Name+Network"
    NSString *generatedClassName = [NSString stringWithFormat:@"SP%@Network", trimmedNetworkName];

    NSArray *possibleClassNames = @[ generatedClassName ];
    NSArray *mappingClassNames = networkNameToClassMapping[networkName];

    // add the class names from mapping
    if (mappingClassNames) {
        possibleClassNames = [possibleClassNames arrayByAddingObjectsFromArray:mappingClassNames];
    }


    [possibleClassNames enumerateObjectsUsingBlock:^(NSString *networkClassName, NSUInteger idx, BOOL *stop) {
        Class NetworkClass = NSClassFromString(networkClassName);

        if (!NetworkClass) {
            return; // continue to next name
        }


        if (![NetworkClass isSubclassOfClass:[SPBaseNetwork class]]) {
            SPLogError(@"Class %@ is not a subclass of %@", NSStringFromClass(NetworkClass), NSStringFromClass([SPBaseNetwork class]));
            return;

        }

        if (![self isAdapterVersionValid:[NetworkClass adapterVersion]]) {
            SPLogError(@"Could not add %@: Adapter version is %@ but this SDK version support only adapters with version %d.X.X", networkName, [NetworkClass adapterVersion], SPAdapterSupportedVersion);
            return;
        }

        // all good, we have a matching classs
        foundNetworkClass = NetworkClass;
        *stop = YES;

    }];

    if (!foundNetworkClass) {
        SPLogError(@"Class for network %@ could not be found, Tried %@", networkName, possibleClassNames);
    }

    return foundNetworkClass;
}

@end
