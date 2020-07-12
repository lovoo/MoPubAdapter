//
//  IASDKMopubAdapterData.h
//  FyberMarketplaceTestApp
//
//  Created by Fyber on 16/12/2017.
//  Copyright © 2017 Fyber. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

/**
 *  @brief IASDK Mopub Adapter Data
 *
 *  @discussion Use to pass location and keywords to Mopub Rewarded Video Custom Event Class.
 */
@interface IASDKMopubAdapterData : NSObject

@property (nonatomic, strong, nullable) CLLocation *location;

/**
 *  @brief Key-words separated by comma.
 */
@property (nonatomic, strong, nullable) NSString *keywords;

@end
NS_ASSUME_NONNULL_END
