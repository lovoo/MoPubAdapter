//
//  InneractiveRewardedVideoCustomEvent.h
//  FyberMarketplaceTestApp
//
//  Created by Fyber 02/08/2017.
//  Copyright (c) 2017 Fyber. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDK/MoPub.h>)
#import <MoPubSDK/MoPub.h>
#else
#import <MoPub.h>
#endif

/**
 *  @brief Rewarded Video Custom Event Class for MoPub SDK.
 *
 *  @discussion Use in order to implement mediation with Inneractive Rewarded Video Ads.
 */
@interface InneractiveRewardedVideoCustomEvent : MPFullscreenAdAdapter <MPThirdPartyFullscreenAdAdapter>

@end
#warning The InneractiveRewardedVideoCustomEvent class will be renamed to the InneractiveRewardedCustomEvent in the 7.6.1 version.
typedef InneractiveRewardedVideoCustomEvent InneractiveRewardedCustomEvent;
