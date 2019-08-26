//
//  InneractiveInterstitialCustomEvent.h
//  IASDKClient
//
//  Created by Inneractive 10/04/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#else
#import "MPInterstitialCustomEvent.h"
#endif

/**
 *  @brief Interstitial Custom Event Class for MoPub SDK.
 *
 *  @discussion Use in order to implement mediation with Inneractive Interstitial Ads.
 */
@interface InneractiveInterstitialCustomEvent : MPInterstitialCustomEvent

@end
