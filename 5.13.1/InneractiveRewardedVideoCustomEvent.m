//
//  InneractiveRewardedVideoCustomEvent.m
//  FyberMarketplaceTestApp
//
//  Created by Fyber 02/08/2017.
//  Copyright (c) 2017 Fyber. All rights reserved.
//

#import "InneractiveRewardedVideoCustomEvent.h"

#import "IASDKMopubAdapterConfiguration.h"
#import "IASDKMopubAdapterData.h"

#import "MPLogging.h"
#import "MPRewardedVideoReward.h"

#import <IASDKCore/IASDKCore.h>
#import <IASDKMRAID/IASDKMRAID.h>
#import <IASDKVideo/IASDKVideo.h>

@interface InneractiveRewardedVideoCustomEvent () <IAUnitDelegate, IAMRAIDContentDelegate, IAVideoContentDelegate>

@property (nonatomic, strong) IAAdSpot *adSpot;
@property (nonatomic, strong) IAFullscreenUnitController *interstitialUnitController;
@property (nonatomic, strong) IAMRAIDContentController *MRAIDContentController;
@property (nonatomic, strong) IAVideoContentController *videoContentController;
@property (nonatomic) BOOL isVideoAvailable;
@property (nonatomic, strong) NSString *spotID;
@property (nonatomic) BOOL clickTracked;

/**
 *  @brief The view controller, that presents the Inneractive Interstitial Ad.
 */
@property (nonatomic, weak) UIViewController *viewControllerForPresentingModalView;

@end

@implementation InneractiveRewardedVideoCustomEvent {}

@dynamic delegate;
@dynamic hasAdAvailable;
@dynamic localExtras;

#pragma mark - MPRewardedVideoCustomEvent

/**
 *
 *  @brief Is called each time the MoPub SDK requests a new rewarded video ad. MoPub >= 5.13.
 *
 *  @param info A dictionary containing additional custom data associated with a given custom event
 * request. This data is configurable on the MoPub website, and may be used to pass a dynamic information, such as spotID.
 */
- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
#warning Set your spotID or define it @MoPub console inside the "extra" JSON:
    NSString *spotID = @"";
    
    if (info && [info isKindOfClass:NSDictionary.class] && info.count) {
        NSString *receivedSpotID = info[@"spotID"];
        
        if (receivedSpotID && [receivedSpotID isKindOfClass:NSString.class] && receivedSpotID.length) {
            spotID = receivedSpotID;
        }
        
        [IASDKMopubAdapterConfiguration configureIASDKWithInfo:info];
    }
    [IASDKMopubAdapterConfiguration collectConsentStatusFromMopub];
    
    IAUserData *userData = [IAUserData build:^(id<IAUserDataBuilder>  _Nonnull builder) {
#warning Set up targeting in order to increase revenue:
        /*
         builder.age = 34;
         builder.gender = IAUserGenderTypeMale;
         builder.zipCode = @"90210";
         */
    }];
    
	IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
		builder.spotID = spotID;
		builder.timeout = 15;
		builder.userData = userData;
        builder.keywords = self.localExtras[@"keywords"];
	}];
    
    self.MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {
        builder.MRAIDContentDelegate = self;
    }];
	
    self.videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
		builder.videoContentDelegate = self;
	}];

	self.interstitialUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
		builder.unitDelegate = self;
		
        [builder addSupportedContentController:self.MRAIDContentController];
		[builder addSupportedContentController:self.videoContentController];
	}];

	self.adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
		builder.adRequest = request;
		[builder addSupportedUnitController:self.interstitialUnitController];
        builder.mediationType = [IAMediationMopub new];
	}];
    
    self.spotID = spotID;
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], self.spotID);
    
    if (IASDKCore.sharedInstance.isInitialised) {
        __weak __typeof__(self) weakSelf = self;
        
        [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) { // 'self' should not be used in this block;
            if (error) {
                [weakSelf treatLoadOrShowError:error.localizedDescription isLoad:YES];
            } else {
                if (adSpot.activeUnitController == weakSelf.interstitialUnitController) {
                    weakSelf.isVideoAvailable = YES;
                    [MPLogging logEvent:[MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(weakSelf.class)] source:weakSelf.spotID fromClass:weakSelf.class];
                    [weakSelf.delegate fullscreenAdAdapterDidLoadAd:weakSelf];
                } else {
                    [weakSelf treatLoadOrShowError:nil isLoad:YES];
                }
            }
        }];
    } else {
        [self treatLoadOrShowError:@"<Fyber> SDK is not initialised;" isLoad:YES];
    }
}

- (BOOL)hasAdAvailable {
    return self.isVideoAvailable;
}

- (void)presentAdFromViewController:(UIViewController *)viewController {
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], self.spotID);
    
    NSString *errorString = nil;
    
    if (!viewController) {
        errorString = @"viewController must not be nil;";
    } else if (self.interstitialUnitController.isPresented) {
        errorString = @"the rewarded ad is already presented;";
    } else if (!self.isVideoAvailable) {
        errorString = @"requesting video presentation before it is ready;";
    } else if (!self.interstitialUnitController.isReady) {
        errorString = @"ad did expire;";
    }

    if (errorString) {
        [self treatLoadOrShowError:errorString isLoad:NO];
    } else {
        self.viewControllerForPresentingModalView = viewController;
        [self.interstitialUnitController showAdAnimated:YES completion:nil];
    }
}

// new
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO; // we will track it manually;
}

- (BOOL)isRewardExpected {
    return YES;
}

- (void)handleDidPlayAd {
    if (!self.hasAdAvailable) {
        [self.delegate fullscreenAdAdapterDidExpire:self];
    }
}

#pragma mark - Service

- (void)treatLoadOrShowError:(NSString * _Nullable)reason isLoad:(BOOL)isLoad {
    if (!reason.length) {
        reason = @"internal error";
    }
    
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : reason};
    NSError *error = [NSError errorWithDomain:kIASDKMopubAdapterErrorDomain code:IASDKMopubAdapterErrorInternal userInfo:userInfo];
    
    if (isLoad) {
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], self.spotID);
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
    } else {
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:error], self.spotID);
    }
}

#pragma mark - IAViewUnitControllerDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return self.viewControllerForPresentingModalView;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.spotID);
	[self.delegate fullscreenAdAdapterDidReceiveTap:self];
    if (!self.clickTracked) {
        self.clickTracked = YES;
        [self.delegate fullscreenAdAdapterDidTrackClick:self]; // manual track;
    }
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], self.spotID);
    [self.delegate fullscreenAdAdapterDidTrackImpression:self]; // manual track;
}

// in order to use the rewarded callback for all available rewarded content, you will have to implement this method (not the `IAVideoCompleted:`;
- (void)IAAdDidReward:(IAUnitController * _Nullable)unitController {
    #warning Set desired reward or pass it via Mopub console JSON (info object), or via IASDKMediationSettings object and connect it here:
    MPRewardedVideoReward *reward = [[MPRewardedVideoReward alloc] initWithCurrencyType:kMPRewardCurrencyTypeUnspecified
                                                                                 amount:@(kMPRewardCurrencyAmountUnspecified)];
    
    [self.delegate fullscreenAdAdapter:self willRewardUser:reward];
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], self.spotID);
    [self.delegate fullscreenAdAdapterAdWillAppear:self];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], self.spotID);
    [self.delegate fullscreenAdAdapterAdDidAppear:self];
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], self.spotID);
    [self.delegate fullscreenAdAdapterAdWillDisappear:self];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], self.spotID);
    [self.delegate fullscreenAdAdapterAdDidDisappear:self];
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], self.spotID);
    [self.delegate fullscreenAdAdapterWillLeaveApplication:self];
}

- (void)IAAdDidExpire:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Fyber> IAAdDidExpire");
}

#pragma mark - IAMRAIDContentDelegate

// MRAID protocol related methods are not relevant in case of interstitial;

#pragma mark - IAVideoContentDelegate

- (void)IAVideoCompleted:(IAVideoContentController * _Nullable)contentController {
    MPLogInfo(@"<Fyber> video completed;");
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController videoInterruptedWithError:(NSError *)error {
    MPLogInfo(@"<Fyber> video error: %@;", error.localizedDescription);
    [self.delegate fullscreenAdAdapter:self didFailToShowAdWithError:error];
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController videoDurationUpdated:(NSTimeInterval)videoDuration {
    MPLogInfo(@"<Fyber> video duration updated: %.02lf", videoDuration);
}

// Implement if needed:
/*
 - (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController videoProgressUpdatedWithCurrentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
 
 }
 */

#pragma mark - Memory management

- (void)dealloc {
    MPLogDebug(@"%@ deallocated", NSStringFromClass(self.class));
}

@end
