//
//  IASDKMopubAdapterConfiguration.m
//  FyberMarketplaceTestApp
//
//  Created by Fyber on 2/25/19.
//  Copyright © 2019 Fyber. All rights reserved.
//

#import "IASDKMopubAdapterConfiguration.h"

#import <IASDKCore/IASDKCore.h>

@implementation IASDKMopubAdapterConfiguration

#pragma mark - Consts

NSString * const kIASDKMopubAdapterAppIDKey = @"appID";
NSString * const kIASDKMopubAdapterErrorDomain = @"com.mopub.IASDKAdapter";
NSString * const kIASDKShouldUseMopubGDPRConsentKey = @"IASDKShouldUseMopubGDPRConsentKey";
NSNotificationName _Nonnull kIASDKInitCompleteNotification = @"kIASDKInitCompleteNotification";

#pragma mark - Static members

static dispatch_queue_t sIASDKInitSyncQueue = nil;

+ (void)initialize {
    static BOOL initialised = NO;
    
    if ((self == IASDKMopubAdapterConfiguration.self) && !initialised) { // invoke only once per application runtime (and not in subclasses);
        initialised = YES;
        
        sIASDKInitSyncQueue = dispatch_queue_create("com.Fyber.SDK.Marketplace.mediation.mopub.init", DISPATCH_QUEUE_SERIAL);
    }
}

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    NSString *version = @"";
    
    if (IASDKCore.sharedInstance.version) {
        version = [NSString stringWithFormat:@"%@.0", IASDKCore.sharedInstance.version];
    }
    
    return version;
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
    // This should match your Mopub Dashboard settings;
    return @"inneractive";
}

- (NSString *)networkSdkVersion {
    return IASDKCore.sharedInstance.version;
}

#pragma mark - Overrides

// new
- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> *)configuration complete:(void(^)(NSError *))complete {
    NSString *appID = configuration[kIASDKMopubAdapterAppIDKey];
    
    if ([appID isEqualToString:IASDKCore.sharedInstance.appID]) { // already initialised;
        if (complete) {
            complete(nil);
        }
    } else {
        dispatch_async(sIASDKInitSyncQueue, ^{
            [IASDKCore.sharedInstance initWithAppID:appID completionBlock:^(BOOL success, NSError * _Nullable error) {
                if (success || (error.code == IASDKCoreInitErrorTypeFailedToDownloadMandatoryData)) {
                    error = nil;
                    [NSNotificationCenter.defaultCenter postNotificationName:kIASDKInitCompleteNotification object:self];
                }
                
                if (complete) {
                    complete(error);
                }
                
                if (error) {
                    NSInteger errorCode = IASDKMopubAdapterErrorSDKInit;
                    
                    if (!appID.length) {
                        errorCode = IASDKMopubAdapterErrorMissingAppID;
                    }
                    
                    error = [NSError errorWithDomain:kIASDKMopubAdapterErrorDomain code:errorCode userInfo:error.userInfo];
                    MPLogEvent([MPLogEvent error:error message:error.description ?: @""]);
                } else {
                    [self.class setCachedInitializationParameters:configuration];
                }
            } completionQueue:nil];
        });
    }
}

#pragma mark - static API

+ (void)configureIASDKWithInfo:(NSDictionary *)info {
    NSString *receivedAppID = info[kIASDKMopubAdapterAppIDKey];
    
    dispatch_async(sIASDKInitSyncQueue, ^{
        if (receivedAppID && [receivedAppID isKindOfClass:NSString.class] && receivedAppID.length && ![receivedAppID isEqualToString:IASDKCore.sharedInstance.appID]) {
            [IASDKCore.sharedInstance initWithAppID:receivedAppID completionBlock:^(BOOL success, NSError * _Nullable error) {
                [NSNotificationCenter.defaultCenter postNotificationName:kIASDKInitCompleteNotification object:self];
            } completionQueue:nil];
        }
    });
}

+ (void)collectConsentStatusFromMopub {
    BOOL shouldUseMopubGDPRConsent =
    [NSUserDefaults.standardUserDefaults boolForKey:kIASDKShouldUseMopubGDPRConsentKey] ||
    (IASDKCore.sharedInstance.GDPRConsent == IAGDPRConsentTypeUnknown);
    
    if (shouldUseMopubGDPRConsent && (MoPub.sharedInstance.isGDPRApplicable == MPBoolYes)) {
        if (MoPub.sharedInstance.allowLegitimateInterest) {
            if ((MoPub.sharedInstance.currentConsentStatus == MPConsentStatusDenied) ||
                (MoPub.sharedInstance.currentConsentStatus == MPConsentStatusPotentialWhitelist)) {
                IASDKCore.sharedInstance.GDPRConsent = IAGDPRConsentTypeDenied;
            } else {
                IASDKCore.sharedInstance.GDPRConsent = IAGDPRConsentTypeGiven;
            }
        } else {
            const BOOL canCollectPersonalInfo = MoPub.sharedInstance.canCollectPersonalInfo;
            
            IASDKCore.sharedInstance.GDPRConsent = (canCollectPersonalInfo) ? IAGDPRConsentTypeGiven : IAGDPRConsentTypeDenied;
        }
        
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:kIASDKShouldUseMopubGDPRConsentKey];
    }
}

@end

