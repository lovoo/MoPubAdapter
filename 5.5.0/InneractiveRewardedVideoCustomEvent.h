//
//  InneractiveRewardedVideoCustomEvent.h
//  IASDKClient
//
//  Created by Inneractive 02/08/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#else
#import "MPRewardedVideoCustomEvent.h"
#endif

/**
 *  @brief Rewarded Video Custom Event Class for MoPub SDK.
 *
 *  @discussion Use in order to implement mediation with Inneractive Rewarded Video Ads.
 */
@interface InneractiveRewardedVideoCustomEvent : MPRewardedVideoCustomEvent

@end
