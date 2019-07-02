//
//  InneractiveInterstitialCustomEvent.m
//  IASDKClient
//
//  Created by Inneractive 10/04/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#import "InneractiveInterstitialCustomEvent.h"

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

/**
 *  @brief The view controller, that presents the Inneractive Interstitial Ad.
 */
@property (nonatomic, weak) UIViewController *interstitialRootViewController;

@end

@implementation InneractiveInterstitialCustomEvent {}

/**
 *  @brief Called when the MoPub SDK requires a new interstitial ad.
 *  @discussion The Inneractive interstitial ad will be created in this method.
 *
 *  @param info Info dictionary - a JSON object defined at MoPub console.
 */
- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info {
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
    
    MPBaseInterstitialAdapter *baseInterstitialAdapter = (MPBaseInterstitialAdapter *)self.delegate;
    MPInterstitialAdController *interstitialAdController = baseInterstitialAdapter.delegate.interstitialAdController;
    
	IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
#warning In case of using ATS, please set to YES 'useSecureConnections' property:
		builder.useSecureConnections = NO;
		builder.spotID = spotID;
		builder.timeout = 15;
        builder.userData = userData;
		builder.keywords = interstitialAdController.keywords;
		builder.location = self.delegate.location;
	}];
	
	_videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
		builder.videoContentDelegate = self;
	}];
	
	_MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {
		builder.MRAIDContentDelegate = self;
	}];
	
	_interstitialUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
		builder.unitDelegate = self;
		
		[builder addSupportedContentController:self.videoContentController];
		[builder addSupportedContentController:self.MRAIDContentController];
	}];
	
	_adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
		builder.adRequest = request;
		[builder addSupportedUnitController:self.interstitialUnitController];
		builder.mediationType = [IAMediationMopub new];
	}];
	
	__weak typeof(self) weakSelf = self; // a weak reference to 'self' should be used in the next block:
	
	[self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
		if (error) {
			MPLogError(@"<Inneractive> ad failed with error: %@;", error);
			[weakSelf.delegate interstitialCustomEvent:weakSelf didFailToLoadAdWithError:error];
		} else {
			if (adSpot.activeUnitController == weakSelf.interstitialUnitController) {
				MPLogInfo(@"<Inneractive> ad loaded;");
				[weakSelf.delegate interstitialCustomEvent:weakSelf didLoadAd:adModel];
			} else {
				MPLogError(@"<Inneractive> ad failed with internal error;");
				[weakSelf.delegate interstitialCustomEvent:weakSelf didFailToLoadAdWithError:[NSError errorWithDomain:@"internal error" code:0 userInfo:nil]];
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
    if (rootViewController) {
        self.interstitialRootViewController = rootViewController;
		[self.interstitialUnitController showAdAnimated:YES completion:nil];
    } else {
        MPLogError(@"<Inneractive> error: rootViewController must not be nil. Will not show the ad.");
    }
}

// new
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO; // we will track it manually;
}

#pragma mark - IAViewUnitControllerDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
	return self.interstitialRootViewController;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
	MPLogInfo(@"<Inneractive> ad clicked;");
	[self.delegate interstitialCustomEventDidReceiveTapEvent:self];
    [self.delegate trackClick]; // manual track;
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
	MPLogInfo(@"<Inneractive> ad impression;");
    [self.delegate trackImpression]; // manual track;
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
	MPLogInfo(@"<Inneractive> ad will present fullscreen;");
	[self.delegate interstitialCustomEventWillAppear:self];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
	MPLogInfo(@"<Inneractive> ad did present fullscreen;");
	[self.delegate interstitialCustomEventDidAppear:self];
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
	MPLogInfo(@"<Inneractive> ad will dismiss fullscreen;");
	[self.delegate interstitialCustomEventWillDisappear:self];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
	MPLogInfo(@"<Inneractive> ad did dismiss fullscreen;");
	[self.delegate interstitialCustomEventDidDisappear:self];
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
	MPLogInfo(@"<Inneractive> will open external app;");
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
