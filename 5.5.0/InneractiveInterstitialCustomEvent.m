//
//  InneractiveInterstitialCustomEvent.m
//  IASDKClient
//
//  Created by Inneractive 10/04/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#import "InneractiveInterstitialCustomEvent.h"

#import "IASDKMopubAdapterConfiguration.h"

#import "MPLogging.h"
#import "MPBaseInterstitialAdapter.h"
#import "MPInterstitialAdController.h"

#import <IASDKCore/IASDKCore.h>
#import <IASDKVideo/IASDKVideo.h>
#import <IASDKMRAID/IASDKMRAID.h>

@interface InneractiveInterstitialCustomEvent () <IAUnitDelegate, IAVideoContentDelegate, IAMRAIDContentDelegate>

@property (nonatomic, strong) IAAdSpot *adSpot;
@property (nonatomic, strong) IAFullscreenUnitController *interstitialUnitController;
@property (nonatomic, strong) IAMRAIDContentController *MRAIDContentController;
@property (nonatomic, strong) IAVideoContentController *videoContentController;
@property (nonatomic, strong) NSString *mopubAdUnitID;
@property (nonatomic) BOOL clickTracked;

/**
 *  @brief The view controller, that presents the Inneractive Interstitial Ad.
 */
@property (nonatomic, weak) UIViewController *interstitialRootViewController;

@end

@implementation InneractiveInterstitialCustomEvent {}

/**
 *  @brief Is called each time the MoPub SDK requests a new interstitial ad. MoPub < 5.10.
 
 *  @discussion The Inneractive interstitial ad will be created in this method.
 *
 *  @param info An Info dictionary is a JSON object that is defined in the MoPub console.
 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-implementations"
- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info {
    [self requestInterstitialWithCustomEventInfo:info adMarkup:nil];
}
#pragma GCC diagnostic pop

/**
 *  @brief MoPub 5.10+.
 */
- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
#warning Set your spotID or define it @MoPub console inside the "extra" JSON:
    NSString *spotID = @"";
    
    if (info && [info isKindOfClass:NSDictionary.class] && info.count) {
        NSString *receivedSpotID = info[@"spotID"];
        
        if (receivedSpotID && [receivedSpotID isKindOfClass:NSString.class] && receivedSpotID.length) {
            spotID = receivedSpotID;
        }
        
        [IASDKMopubAdapterConfiguration configureIASDKWithInfo:info];
    }
    
    IAUserData *userData = [IAUserData build:^(id<IAUserDataBuilder>  _Nonnull builder) {
#warning Set up targeting in order to increase revenue:
        /*
        builder.age = 34;
        builder.gender = IAUserGenderTypeMale;
        builder.zipCode = @"90210";
         */
    }];
    
    MPBaseInterstitialAdapter *baseInterstitialAdapter = (MPBaseInterstitialAdapter *)self.delegate;
    MPInterstitialAdController *interstitialAdController = baseInterstitialAdapter.delegate.interstitialAdController;
    
    self.mopubAdUnitID = interstitialAdController.adUnitId;
	IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
#warning In case of using ATS, please set to YES 'useSecureConnections' property:
		builder.useSecureConnections = NO;
		builder.spotID = spotID;
		builder.timeout = 15;
        builder.userData = userData;
		builder.keywords = interstitialAdController.keywords;
		builder.location = self.delegate.location;
	}];

	self.videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
		builder.videoContentDelegate = self;
	}];
	
	self.MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {
		builder.MRAIDContentDelegate = self;
	}];
	
	self.interstitialUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
		builder.unitDelegate = self;
		
		[builder addSupportedContentController:self.videoContentController];
		[builder addSupportedContentController:self.MRAIDContentController];
	}];
	
    self.adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
		builder.adRequest = request;
		[builder addSupportedUnitController:self.interstitialUnitController];
		builder.mediationType = [IAMediationMopub new];
	}];
	MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], self.mopubAdUnitID);
    
	__weak __typeof__(self) weakSelf = self; // a weak reference to 'self' should be used in the next block:
	
	[self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
		if (error) {
            [weakSelf treatLoadOrShowError:error.localizedDescription isLoad:YES];
		} else {
			if (adSpot.activeUnitController == weakSelf.interstitialUnitController) {
                [MPLogging logEvent:[MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(weakSelf.class)] source:weakSelf.mopubAdUnitID fromClass:weakSelf.class];
				[weakSelf.delegate interstitialCustomEvent:weakSelf didLoadAd:adModel];
			} else {
                [weakSelf treatLoadOrShowError:nil isLoad:YES];
			}
		}
	}];
}

/**
 *  @brief Shows the interstitial ad.
 *
 *  @param rootViewController The view controller, that will present Inneractive interstitial ad.
 */
- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController {
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    
    NSString *errorString = nil;
    
    if (!rootViewController) {
        errorString = @"rootViewController must not be nil;";
    } else if (self.interstitialUnitController.isPresented) {
        errorString = @"the interstitial ad is already presented;";
    }
    
    if (errorString) {
        [self treatLoadOrShowError:errorString isLoad:NO];
    } else {
        self.interstitialRootViewController = rootViewController;
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
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
    } else {
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:error], self.mopubAdUnitID);
    }
}

#pragma mark - IAViewUnitControllerDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
	return self.interstitialRootViewController;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
	[self.delegate interstitialCustomEventDidReceiveTapEvent:self];
    if (!self.clickTracked) {
        self.clickTracked = YES;
        [self.delegate trackClick]; // manual track;
    }
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate trackImpression]; // manual track;
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
	[self.delegate interstitialCustomEventWillAppear:self];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
	MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
	[self.delegate interstitialCustomEventDidAppear:self];
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate interstitialCustomEventWillDisappear:self];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
	[self.delegate interstitialCustomEventDidDisappear:self];
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
	[self.delegate interstitialCustomEventWillLeaveApplication:self];
}

#pragma mark - IAMRAIDContentDelegate

// MRAID protocol related methods are not relevant in case of interstitial;

#pragma mark - IAVideoContentDelegate

- (void)IAVideoCompleted:(IAVideoContentController * _Nullable)contentController {
    MPLogInfo(@"<Inneractive> video completed;");
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController videoInterruptedWithError:(NSError *)error {
    MPLogInfo(@"<Inneractive> video error: %@;", error.localizedDescription);
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
