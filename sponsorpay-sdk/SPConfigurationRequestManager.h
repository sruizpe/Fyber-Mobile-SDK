//
//  SPConfigurationRequestManager.h
//  SponsorPaySDK
//
//  Created by Piotr on 6/17/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SPConfigurationSuccessBlock)(NSArray *networks);
typedef void (^SPConfigurationFailedBlock)(NSError *error);

extern NSString *const SPNetworkName;
extern NSString *const SPNetworks;
extern NSString *const SPNetworkParameters;

@class SPCredentials;

/**
 `SPConfigurationRequestManager` handles request for configuration files for all available `networks`. Configuration file is either fetched from server or parsed from local cache folder.
 */

@interface SPConfigurationRequestManager : NSObject

/**
 Optional block for handling failed request
 
 @note This block property is called not only when remote network operation fails but also when json file is corrupt or in case when device network and cached config file are unavailable.
 */
@property (copy) SPConfigurationFailedBlock  configurationFailedBlock;

/**
 Initializes an `SPConfigurationRequestManager` object with completionBlock.

 @param completionBlock A block object to be executed when the request for configuration finishes. This block has no return value and takes 1 argument: networks that represents list of networks and their respective configuration parameters.
 
 @note completion block is excecuted in -requestConfiguration method
 @see -requestConfiguration
 */
- (id) initWithCredentials:(SPCredentials *)credentials completionBlock:(SPConfigurationSuccessBlock)completionBlock ;

/**
 Requests configuration parameters for all available networks
 */
- (void) requestConfiguration;

@end
