//
//  SPConfigurationRequestManager+Debug.m
//  SponsorPaySDK
//
//  Created by Piotr  on 02/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPConfigurationRequestManager+Debug.h"
#import "SPGlobalUtilities.h"
#import "SPLogger.h"
#import "NSDictionary+SPSerialization.h"



@implementation SPConfigurationRequestManager (Debug)

#pragma mark - Public

// This method overrides configuration in dev environment.
// It takes settings from local plist file and replaces values for corresponding keys.
// If you don't want to replace any values in debug mode add user define flag IGNORE_LOCAL_ADAPTERS_SETTINGS.
- (NSMutableArray *) overrideSettings:(NSMutableArray *)adapters {

    NSArray *localPlistAdapters = [[NSBundle mainBundle] objectForInfoDictionaryKey:SPNetworks];
    if (!localPlistAdapters || ![localPlistAdapters count]) {
        return nil; // Nothing to replace
    }
    
    // Match list of returned adapters with local ones
    // store them in NSSet and loop through.
    // Local plist configuration takes the priority over the remote values
    NSArray *collections    = [adapters arrayByAddingObjectsFromArray:localPlistAdapters];
    NSSet *listOfAdapters   = [self adapterNames:collections];
    
    NSMutableArray *freshAdapters = [NSMutableArray array];
    [listOfAdapters enumerateObjectsUsingBlock:^(NSString *adapterName, BOOL *stop) {
        // Enumerate adapters obtained from server and if found add to array
        NSMutableDictionary *adapter = [self filterAdapters:adapters name:adapterName];
        if (adapter) {
            [freshAdapters addObject:adapter];
        }
        
        // If adapter instance is empty just add adapter from plist, otherwise replace values
        if (!adapter) {
            NSDictionary *plistAdapter          = [self filterAdapters:localPlistAdapters name:adapterName];
            NSMutableDictionary *mutableAdapter = [self mutableCopy:plistAdapter];  // plistAdapter is immutable so it needs to be mutaded in order to remove credentials


            if (mutableAdapter) {
                [freshAdapters addObject:[mutableAdapter copy]];
            }
        } else {
            // Adapter also stored in plist
            NSDictionary *plistAdapter = [self filterAdapters:localPlistAdapters name:adapterName];
            if (!plistAdapter) {
                return;
            }
            
            NSMutableDictionary *settings = adapter.adapterSettings;

            [plistAdapter.adapterSettings enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                settings[key] = value;
            }];
        }
    }];
    
    return freshAdapters;
}

#pragma mark - Private

- (NSSet *) adapterNames:(NSArray *)names {
    __block NSMutableSet *listOfAdapters = [NSMutableSet set];
    // Collect all available adapters - union of adapters from json and plist file
    [names enumerateObjectsUsingBlock:^(NSDictionary *adapter, NSUInteger idx, BOOL *stop) {
        if (!adapter.adapterName) {
            return;
        }
        [listOfAdapters addObject:adapter.adapterName];
    }];
    
    return [listOfAdapters copy];
}


- (id) mutableCopy:(id)object {
    id returnObj;
    if (!object) {
        return nil;
    }
    CFPropertyListRef objRef = CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFPropertyListRef)object, kCFPropertyListMutableContainers);
    if ([object isKindOfClass:[NSArray class]]) {
        returnObj = (__bridge_transfer NSMutableArray *)objRef;
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        returnObj = (__bridge_transfer NSMutableDictionary *)objRef;
    } else {
        CFRelease(objRef);
    }

    return returnObj;
}

- (id)filterAdapters:(id)adapters name:(NSString *)adapterName{
    for (id adapter in (NSArray *)adapters) {
        if ([[(NSDictionary *)adapter adapterName] isEqualToString:adapterName]) {
            return adapter;
        }
    }
    return nil;
}

@end
