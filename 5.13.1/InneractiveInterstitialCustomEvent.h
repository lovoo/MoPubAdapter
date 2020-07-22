//
//  InneractiveInterstitialCustomEvent.h
//  FyberMarketplaceTestApp
//
//  Created by Fyber 10/04/2017.
//  Copyright (c) 2017 Fyber. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#else
#import "MPFullscreenAdAdapter.h"
#endif

/**
 *  @brief Interstitial Custom Event Class for MoPub SDK.
 *
 *  @discussion Use in order to implement mediation with Inneractive Interstitial Ads.
 */
@interface InneractiveInterstitialCustomEvent : MPFullscreenAdAdapter <MPThirdPartyFullscreenAdAdapter>

@end
