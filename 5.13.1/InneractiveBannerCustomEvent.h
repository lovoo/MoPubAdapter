//
//  InneractiveBannerCustomEvent.h
//  FyberMarketplaceTestApp
//
//  Created by Fyber 05/04/2017.
//  Copyright (c) 2017 Fyber. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#else
#import <MoPub.h>
#endif

/**
 *  @brief Banner Custom Event Class for MoPub SDK.
 *
 *  @discussion Use in order to implement mediation with Inneractive Banner Ads.
 */
@interface InneractiveBannerCustomEvent : MPInlineAdAdapter <MPThirdPartyInlineAdAdapter>

@end
