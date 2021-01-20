//
//  IASDKMopubAdapterConfiguration.m
//  FyberMarketplaceTestApp
//
//  Created by Fyber on 2/25/19.
//  Copyright © 2019 Fyber. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDK/MoPub.h>)
#import <MoPubSDK/MoPub.h>
#else
#import <MoPub.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IASDKMopubAdapterError) {
    IASDKMopubAdapterErrorUnknown = 1,
    IASDKMopubAdapterErrorMissingAppID,
    IASDKMopubAdapterErrorSDKInit,
    IASDKMopubAdapterErrorInternal,
};

extern NSString * const kIASDKMopubAdapterAppIDKey;
extern NSString * const kIASDKMopubAdapterErrorDomain;

extern NSNotificationName _Nonnull kIASDKInitCompleteNotification;

/**
 *  @brief The Inneractive Adapter Configuration class.
 *
 *  @discussion This adapter set of classes is supported only and only by the VAMP SDK that it is shipped with.
 */
@interface IASDKMopubAdapterConfiguration : MPBaseAdapterConfiguration

+ (void)configureIASDKWithInfo:(NSDictionary *)info;

/**
 *  @brief Collects and passes the user's consent from MoPub into the Marketplace SDK.
 */
+ (void)collectConsentStatusFromMopub;

@end

NS_ASSUME_NONNULL_END
