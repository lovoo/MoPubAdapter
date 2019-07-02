//
//  InneractiveRewardedVideoCustomEvent.m
//  IASDKClient
//
//  Created by Inneractive 02/08/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#import "InneractiveRewardedVideoCustomEvent.h"

#import "IASDKMopubAdapterConfiguration.h"
#import "IASDKMopubAdapterData.h"

#import "MPLogging.h"
#import "MPRewardedVideoReward.h"
#import "MPRewardedVideoAdapter.h"

#import <IASDKCore/IASDKCore.h>
#import <IASDKVideo/IASDKVideo.h>

@interface InneractiveRewardedVideoCustomEvent () <IAUnitDelegate, IAVideoContentDelegate>

@property (nonatomic, strong) IAAdSpot *adSpot;
@property (nonatomic, strong) IAFullscreenUnitController *interstitialUnitController;
@property (nonatomic, strong) IAVideoContentController *videoContentController;
@property (nonatomic) BOOL isVideoAvailable;
@property (nonatomic, strong) NSString *mopubAdUnitID;

/**
 *  @brief The view controller, that presents the Inneractive Interstitial Ad.
 */
@property (nonatomic, weak) UIViewController *viewControllerForPresentingModalView;

@end

@implementation InneractiveRewardedVideoCustomEvent {}

#pragma mark - MPRewardedVideoCustomEvent

/**
 *
 *  @brief Is called each time the MoPub SDK requests a new rewarded video ad.
 *
 *  @param info A dictionary containing additional custom data associated with a given custom event
 * request. This data is configurable on the MoPub website, and may be used to pass a dynamic information, such as spotID.
 */
- (void)requestRewardedVideoWithCustomEventInfo:(NSDictionary *)info {
#warning Set your spotID or define it @MoPub console inside the "extra" JSON:
    NSString *spotID = @"";
    
    if (info && [info isKindOfClass:NSDictionary.class] && info.count) {
        NSString *receivedSpotID = info[@"spotID"];
        
        if (receivedSpotID && [receivedSpotID isKindOfClass:NSString.class] && receivedSpotID.length) {
            spotID = receivedSpotID;
        }
    }
    
    IAUserData *userData = [IAUserData build:^(id<IAUserDataBuilder>  _Nonnull builder) {
#warning Set up targeting in order to increase revenue:
        /*
         builder.age = 34;
         builder.gender = IAUserGenderTypeMale;
         builder.zipCode = @"90210";
         */
    }];
    
    IASDKMopubAdapterData *mediationSettings = (IASDKMopubAdapterData *)[self.delegate instanceMediationSettingsForClass:IASDKMopubAdapterData.class];
	IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
#warning In case of using ATS, please set to YES 'useSecureConnections' property:
		builder.useSecureConnections = NO;
		builder.spotID = spotID;
		builder.timeout = 15;
		builder.userData = userData;
        builder.keywords = mediationSettings.keywords;
		builder.location = mediationSettings.location;
	}];
	
    self.videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
		builder.videoContentDelegate = self;
	}];

	self.interstitialUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
		builder.unitDelegate = self;
		
		[builder addSupportedContentController:self.videoContentController];
	}];

	self.adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
		builder.adRequest = request;
		[builder addSupportedUnitController:self.interstitialUnitController];
        builder.mediationType = [IAMediationMopub new];
	}];
    
    MPRewardedVideoAdapter *baseRVAdapter = (MPRewardedVideoAdapter *)self.delegate;
    id<MPRewardedVideoAdapterDelegate> baseRVAdapterDelegate = baseRVAdapter.delegate;
    
    self.mopubAdUnitID = baseRVAdapterDelegate.rewardedVideoAdUnitId;
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], self.mopubAdUnitID);
    
	__weak typeof(self) weakSelf = self;

    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) { // 'self' should not be used in this block;
        if (error) {
            [weakSelf treatLoadOrShowError:error.localizedDescription isLoad:YES];
        } else {
			if (adSpot.activeUnitController == weakSelf.interstitialUnitController) {
                weakSelf.isVideoAvailable = YES;
                [MPLogging logEvent:[MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(weakSelf.class)] source:weakSelf.mopubAdUnitID fromClass:weakSelf.class];
				[weakSelf.delegate rewardedVideoDidLoadAdForCustomEvent:weakSelf];
			} else {
                [weakSelf treatLoadOrShowError:nil isLoad:YES];
			}
        }
    }];
}

- (BOOL)hasAdAvailable {
    return self.isVideoAvailable;
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController {
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);

    if (!viewController) {
        [self treatLoadOrShowError:@"rootViewController must not be a nil. Will not show the ad." isLoad:NO];
    } else if (!self.isVideoAvailable) {
        [self treatLoadOrShowError:@"requesting video presentation before it is ready" isLoad:NO];
    } else {
        self.viewControllerForPresentingModalView = viewController;
        [self.interstitialUnitController showAdAnimated:YES completion:nil];
    }
}

// new
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO; // we will track it manually;
}

#pragma mark - Service

- (void)treatLoadOrShowError:(NSString * _Nullable)reason isLoad:(BOOL)isLoad {
    if (!reason.length) {
        reason = @"internal error";
    }
    
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : reason};
    NSError *error = [NSError errorWithDomain:kIASDKMopubAdapterErrorDomain code:IASDKMopubAdapterErrorInternal userInfo:userInfo];
    
    if (isLoad) {
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], self.mopubAdUnitID);
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
    } else {
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:error], self.mopubAdUnitID);
    }
}

#pragma mark - IAViewUnitControllerDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return self.viewControllerForPresentingModalView;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
	[self.delegate rewardedVideoDidReceiveTapEventForCustomEvent:self];
	[self.delegate trackClick]; // manual track;
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate trackImpression]; // manual track;
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate rewardedVideoWillAppearForCustomEvent:self];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate rewardedVideoDidAppearForCustomEvent:self];
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate rewardedVideoWillLeaveApplicationForCustomEvent:self];
}

#pragma mark - IAVideoContentDelegate

- (void)IAVideoCompleted:(IAVideoContentController * _Nullable)contentController {
    MPLogInfo(@"<Inneractive> video completed;");
#warning Set desired reward or pass it via Mopub console JSON (info object), or via IASDKMediationSettings object and connect it here:
    MPRewardedVideoReward *reward = [[MPRewardedVideoReward alloc] initWithCurrencyType:kMPRewardedVideoRewardCurrencyTypeUnspecified
                                                                                 amount:@(kMPRewardedVideoRewardCurrencyAmountUnspecified)];
    
    [self.delegate rewardedVideoShouldRewardUserForCustomEvent:self reward:reward];
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController videoInterruptedWithError:(NSError *)error {
    MPLogInfo(@"<Inneractive> video error: %@;", error.localizedDescription);
    [self.delegate rewardedVideoDidFailToPlayForCustomEvent:self error:error];
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController videoDurationUpdated:(NSTimeInterval)videoDuration {
    MPLogInfo(@"<Inneractive> video duration updated: %.02lf", videoDuration);
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
