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

@interface IASDKMopubAdapterConfiguration ()

@property (nonatomic, strong, nullable) NSString *mostRecentAppID;

@end

@implementation IASDKMopubAdapterConfiguration

NSString * const kIASDKMopubAdapterAppIDKey = @"appID";
NSString * const kIASDKMopubAdapterErrorDomain = @"com.mopub.IASDKAdapter";

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
        if (![appID isEqualToString:self.mostRecentAppID]) {
            self.mostRecentAppID = appID;
            [IASDKCore.sharedInstance initWithAppID:appID];
        }
        
        [self.class setCachedInitializationParameters:configuration];
    } else {
        errorIfHas = [NSError errorWithDomain:kIASDKMopubAdapterErrorDomain code:IASDKMopubAdapterErrorMissingAppID userInfo:@{NSLocalizedDescriptionKey:@"The VAMP SDK mandatory param appID is missing"}];
        MPLogEvent([MPLogEvent error:errorIfHas message:nil]);
    }
    
    if (complete) {
        complete(errorIfHas);
    }
}

@end
