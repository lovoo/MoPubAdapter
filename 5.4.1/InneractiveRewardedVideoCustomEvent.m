//
//  InneractiveRewardedVideoCustomEvent.m
//  IASDKClient
//
//  Created by Inneractive 02/08/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#import "InneractiveRewardedVideoCustomEvent.h"

#import "IASDKMediationSettings.h"

#import "MPLogging.h"
#import "MPRewardedVideoReward.h"

#import <IASDKCore/IASDKCore.h>
#import <IASDKVideo/IASDKVideo.h>

@interface InneractiveRewardedVideoCustomEvent () <IAUnitDelegate, IAVideoContentDelegate>

@property (nonatomic, strong) IAAdSpot *adSpot;
@property (nonatomic, strong) IAFullscreenUnitController *interstitialUnitController;
@property (nonatomic, strong) IAVideoContentController *videoContentController;
@property (nonatomic) BOOL isVideoAvailable;

/**
 *  @brief The view controller, that presents the Inneractive Interstitial Ad.
 */
@property (nonatomic, weak) UIViewController *viewControllerForPresentingModalView;

@end

@implementation InneractiveRewardedVideoCustomEvent {}

#pragma mark - MPRewardedVideoCustomEvent

- (void)initializeSdkWithParameters:(NSDictionary *)parameters {
    // this method implementation will check whether IASDK was initialised, and will initialise whether was not;
    // it is advised, that IASDK will be initialised in the AppDelegate class, before the invocation of this event;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!IASDKCore.sharedInstance.appID) { // means was never initialised before;
            // Set your AppID here or init the IASDK in the AppDelegate class:
            NSString *appID = nil;
            
            if (appID.length) {
                [[IASDKCore sharedInstance] initWithAppID:appID];
            }
        }
    });
}

/**
 *  @brief Called when the MoPub SDK requires a new rewarded video ad.
 *
 *  @param info A dictionary containing additional custom data associated with a given custom event
 * request. This data is configurable on the MoPub website, and may be used to pass dynamic information, such as publisher IDs.
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
    
    IASDKMediationSettings *mediationSettings = (IASDKMediationSettings *)[self.delegate instanceMediationSettingsForClass:IASDKMediationSettings.class];
	IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
#warning In case of using ATS, please set to YES 'useSecureConnections' property:
		builder.useSecureConnections = NO;
		builder.spotID = spotID;
		builder.timeout = 15;
		builder.userData = userData;
        builder.keywords = mediationSettings.keywords;
		builder.location = mediationSettings.location;
	}];
	
	_videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
		builder.videoContentDelegate = self;
	}];

	_interstitialUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
		builder.unitDelegate = self;
		
		[builder addSupportedContentController:self.videoContentController];
	}];

	_adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
		builder.adRequest = request;
		[builder addSupportedUnitController:self.interstitialUnitController];
        builder.mediationType = [IAMediationMopub new];
	}];
	
	__weak typeof(self) weakSelf = self;

    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) { // 'self' should not be used in this block;
        if (error) {
			MPLogInfo(@"InneractiveAdFailed Error: %@", error);
			[weakSelf.delegate rewardedVideoDidFailToLoadAdForCustomEvent:weakSelf error:error];
        } else {
			if (adSpot.activeUnitController == weakSelf.interstitialUnitController) {
                weakSelf.isVideoAvailable = YES;
				MPLogInfo(@"<Inneractive> ad loaded;");
				[weakSelf.delegate rewardedVideoDidLoadAdForCustomEvent:weakSelf];
			} else {
				MPLogError(@"<Inneractive> ad failed with internal error;");
				[weakSelf.delegate rewardedVideoDidFailToLoadAdForCustomEvent:weakSelf error:[NSError errorWithDomain:@"internal error" code:0 userInfo:nil]];
			}
        }
    }];
}

- (BOOL)hasAdAvailable {
    return self.isVideoAvailable;
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController {
    if (!viewController) {
        MPLogError(@"<Inneractive> error: viewController must not be nil. Will not show the ad.");
    } else if (!self.isVideoAvailable) {
        MPLogError(@"<Inneractive> error: requesting video presentation before it is ready.");
    } else {
        self.viewControllerForPresentingModalView = viewController;
        [self.interstitialUnitController showAdAnimated:YES completion:nil];
        [self.delegate trackImpression]; // manual track;
    }
}

// new
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO; // we will track it manually;
}

#pragma mark - IAViewUnitControllerDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return self.viewControllerForPresentingModalView;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad clicked;");
	[self.delegate rewardedVideoDidReceiveTapEventForCustomEvent:self];
	[self.delegate trackClick]; // manual track;
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad impression;");
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad will present fullscreen;");
    [self.delegate rewardedVideoWillAppearForCustomEvent:self];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad did present fullscreen;");
    [self.delegate rewardedVideoDidAppearForCustomEvent:self];
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad will dismiss fullscreen;");
    [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad did dismiss fullscreen;");
    [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> will open external app;");
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
