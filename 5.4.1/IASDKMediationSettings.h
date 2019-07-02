//
//  IASDKMediationSettings.h
//  IASDKClient
//
//  Created by Inneractive on 16/12/2017.
//  Copyright © 2017 Inneractive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

/**
 *  @brief IASDK Mediation Settings
 *  @discussion Use to pass location and keywords to Mopub Rewarded Video Custom Event Class.
 */
@interface IASDKMediationSettings : NSObject
@property (nonatomic, strong, nullable) CLLocation *location;
/**
 *  @brief Keywords values separated by comma.
 */
@property (nonatomic, strong, nullable) NSString *keywords;
@end
