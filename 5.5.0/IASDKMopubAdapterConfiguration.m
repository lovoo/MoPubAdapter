//
//  IASDKMopubAdapterConfiguration.m
//  IASDKClient
//
//  Created by Inneractive on 2/25/19.
//  Copyright © 2019 Inneractive. All rights reserved.
//

#import "IASDKMopubAdapterConfiguration.h"

#import <IASDKCore/IASDKCore.h>

#import "MPLogging.h"

@implementation IASDKMopubAdapterConfiguration

#pragma mark - Consts

NSString * const kIASDKMopubAdapterAppIDKey = @"appID";
NSString * const kIASDKMopubAdapterErrorDomain = @"com.mopub.IASDKAdapter";

#pragma mark - Static members

static dispatch_queue_t sIASDKInitSyncQueue = nil;

+ (void)initialize {
    static BOOL initialised = NO;
    
    if ((self == IASDKMopubAdapterConfiguration.self) && !initialised) { // invoke only once per application runtime (and not in subclasses);
        initialised = YES;
        
        sIASDKInitSyncQueue = dispatch_queue_create("com.Inneractive.mediation.mopub.init.syncQueue", DISPATCH_QUEUE_SERIAL);
    }
}

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    return IASDKCore.sharedInstance.version;
}

/**
 *  @brief Is not supported in the VAMP SDK.
 *
 *  @discussion Please use the FairBidSDK for the programmatic bidding.
 */
- (NSString *)biddingToken {
    return nil;
}

- (NSString *)moPubNetworkName {
#warning This should match your Mopub Dashboard settings;
    return @"inneractive";
}

- (NSString *)networkSdkVersion {
    return IASDKCore.sharedInstance.version;
}

#pragma mark - Overrides

// new
- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> *)configuration complete:(void(^)(NSError *))complete {
    NSError *errorIfHas = nil;
    NSString *appID = configuration[kIASDKMopubAdapterAppIDKey];
    
    if (appID.length) {
        dispatch_async(sIASDKInitSyncQueue, ^{
            if (![appID isEqualToString:IASDKCore.sharedInstance.appID]) {
                [IASDKCore.sharedInstance initWithAppID:appID];
            }
        });
        
        [self.class setCachedInitializationParameters:configuration];
    } else {
        errorIfHas = [NSError errorWithDomain:kIASDKMopubAdapterErrorDomain code:IASDKMopubAdapterErrorMissingAppID userInfo:@{NSLocalizedDescriptionKey:@"The VAMP SDK mandatory param appID is missing"}];
        MPLogEvent([MPLogEvent error:errorIfHas message:nil]);
    }
    
    if (complete) {
        complete(errorIfHas);
    }
}

#pragma mark - static API

+ (void)configureIASDKWithInfo:(NSDictionary *)info {
    NSString *receivedAppID = info[kIASDKMopubAdapterAppIDKey];
    
    dispatch_async(sIASDKInitSyncQueue, ^{
        if (receivedAppID && [receivedAppID isKindOfClass:NSString.class] && receivedAppID.length && ![receivedAppID isEqualToString:IASDKCore.sharedInstance.appID]) {
            [IASDKCore.sharedInstance initWithAppID:receivedAppID];
        }
    });
}

@end

