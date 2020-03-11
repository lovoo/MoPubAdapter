//
//  InneractiveBannerCustomEvent.m
//  IASDKClient
//
//  Created by Inneractive 05/04/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#import "InneractiveBannerCustomEvent.h"

#import "IASDKMopubAdapterConfiguration.h"

#import "MPConstants.h"
#import "MPLogging.h"
#import "MPBaseBannerAdapter.h"

#import <IASDKCore/IASDKCore.h>
#import <IASDKVideo/IASDKVideo.h>
#import <IASDKMRAID/IASDKMRAID.h>

@interface InneractiveBannerCustomEvent () <IAUnitDelegate, IAVideoContentDelegate, IAMRAIDContentDelegate>

@property (nonatomic, strong) IAAdSpot *adSpot;
@property (nonatomic, strong) IAViewUnitController *bannerUnitController;
@property (nonatomic, strong) IAMRAIDContentController *MRAIDContentController;
@property (nonatomic, strong) IAVideoContentController *videoContentController;
@property (nonatomic, strong) NSString *mopubAdUnitID;
@property (nonatomic, strong) MPAdView *moPubAdView;

@property (nonatomic) BOOL isIABanner;
@property (atomic) BOOL clickTracked;

@end

@implementation InneractiveBannerCustomEvent {}

/**
 *  @brief Is called each time the MoPub SDK requests a new banner ad. MoPub < 5.10.
 *
 *  @discussion Also, when this method is invoked, this class is a new instance, it is not reused,
 * which makes call of this method only once per it's instance lifetime.
 *
 *  @param size Ad size.
 *  @param info An Info dictionary is a JSON object that is defined in the MoPub console.
 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-implementations"
- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info {
    [self requestAdWithSize:size customEventInfo:info adMarkup:nil];
}
#pragma GCC diagnostic pop

/**
 *  @brief MoPub 5.10+.
 */
- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    _isIABanner =
    ((size.width == kIADefaultIPhoneBannerWidth) && (size.height == kIADefaultIPhoneBannerHeight)) ||
    ((size.width == kIADefaultIPadBannerWidth) && (size.height == kIADefaultIPadBannerHeight));
    
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
	
    MPBaseBannerAdapter *baseBannerAdapter = (MPBaseBannerAdapter *)self.delegate;
    MPAdView *mopubAdView = baseBannerAdapter.delegate.banner;
    
    self.mopubAdUnitID = mopubAdView.adUnitId;
	IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
#warning In case of using ATS in order to allow only secure connections, please set to YES 'useSecureConnections' property:
		builder.useSecureConnections = NO;
        builder.spotID = spotID;
		builder.timeout = BANNER_TIMEOUT_INTERVAL - 1;
		builder.userData = userData;
        builder.keywords = mopubAdView.keywords;
        builder.location = self.delegate.location;
	}];
	
	self.videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
		builder.videoContentDelegate = self;
	}];

	self.MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {
		builder.MRAIDContentDelegate = self;
        builder.contentAwareBackground = YES;
	}];

	self.bannerUnitController = [IAViewUnitController build:^(id<IAViewUnitControllerBuilder>  _Nonnull builder) {
		builder.unitDelegate = self;
		
		[builder addSupportedContentController:self.videoContentController];
		[builder addSupportedContentController:self.MRAIDContentController];
	}];

	self.adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
		builder.adRequest = request;
		[builder addSupportedUnitController:self.bannerUnitController];
		builder.mediationType = [IAMediationMopub new];
	}];
	MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], self.mopubAdUnitID);
    self.clickTracked = NO;
    
    __weak __typeof__(self) weakSelf = self; // a weak reference to 'self' should be used in the next block:

    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        if (error) {
            [weakSelf treatError:error.localizedDescription];
        } else {
            if (adSpot.activeUnitController == weakSelf.bannerUnitController) {
                if (weakSelf.isIABanner && [adSpot.activeUnitController.activeContentController isKindOfClass:IAVideoContentController.class]) {
                    [weakSelf treatError:@"incompatible banner content"];
                } else {
					if (weakSelf.delegate.viewControllerForPresentingModalView.presentedViewController != nil) {
                        [weakSelf treatError:@"view hierarchy inconsistency"];
					} else {
                        [MPLogging logEvent:[MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(weakSelf.class)] source:weakSelf.mopubAdUnitID fromClass:weakSelf.class];
                        [MPLogging logEvent:[MPLogEvent adShowAttemptForAdapter:NSStringFromClass(weakSelf.class)] source:weakSelf.mopubAdUnitID fromClass:weakSelf.class];
                        [MPLogging logEvent:[MPLogEvent adWillAppearForAdapter:NSStringFromClass(weakSelf.class)] source:weakSelf.mopubAdUnitID fromClass:weakSelf.class];
                        weakSelf.bannerUnitController.adView.bounds = CGRectMake(0, 0, size.width, size.height);
						[weakSelf.delegate bannerCustomEvent:weakSelf didLoadAd:weakSelf.bannerUnitController.adView];
					}
                }
			} else {
                [weakSelf treatError:@"mismatched ad object entities"];
			}
        }
    }];
}

/**
 *  @discussion This method is called only once per instance lifecycle.
 */
- (void)didDisplayAd {
    // set constraints for rotations support; this method override can be deleted, if rotations treatment is not needed;
    UIView *view = self.bannerUnitController.adView;
    
    if (view.superview) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [view.superview addConstraint:
         [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
        
        [view.superview addConstraint:
         [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
        
        [view.superview addConstraint:
         [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
        
        [view.superview addConstraint:
         [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    }
}

// new
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO; // we will track it manually;
}

#pragma mark - Service

- (void)treatError:(NSString * _Nullable)reason {
    if (!reason.length) {
        reason = @"internal error";
    }
    
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : reason};
    NSError *error = [NSError errorWithDomain:kIASDKMopubAdapterErrorDomain code:IASDKMopubAdapterErrorInternal userInfo:userInfo];
    
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], self.mopubAdUnitID);
    [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
}

#pragma mark - IAViewUnitControllerDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return self.delegate.viewControllerForPresentingModalView;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    if (!self.clickTracked) {
        self.clickTracked = YES;
        [self.delegate trackClick]; // manual track;
    }
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate trackImpression]; // manual track;
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillPresentModalForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad did present fullscreen;");
    UIView *view = self.bannerUnitController.adView;
    
    while (view.superview) {
        if ([view.superview isKindOfClass:MPAdView.class]) {
            self.moPubAdView = (MPAdView *)view.superview;
            [self.moPubAdView stopAutomaticallyRefreshingContents];
            break;
        } else {
            view = view.superview;
        }
    }
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad will dismiss fullscreen;");
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    [self.moPubAdView startAutomaticallyRefreshingContents];
    
    MPLogAdEvent([MPLogEvent adDidDismissModalForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate bannerCustomEventDidFinishAction:self];
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], self.mopubAdUnitID);
    [self.delegate bannerCustomEventWillLeaveApplication:self];
}

#pragma mark - IAMRAIDContentDelegate

- (void)IAMRAIDContentController:(IAMRAIDContentController * _Nullable)contentController MRAIDAdWillResizeToFrame:(CGRect)frame {
    MPLogInfo(@"<Inneractive> MRAID ad will resize;");
}

- (void)IAMRAIDContentController:(IAMRAIDContentController * _Nullable)contentController MRAIDAdDidResizeToFrame:(CGRect)frame {
    MPLogInfo(@"<Inneractive> MRAID ad did resize;");
}

- (void)IAMRAIDContentController:(IAMRAIDContentController * _Nullable)contentController MRAIDAdWillExpandToFrame:(CGRect)frame {
    MPLogInfo(@"<Inneractive> MRAID ad will expand;");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self.delegate respondsToSelector:@selector(bannerCustomEventWillExpandAd:)]) {
        [self.delegate performSelector:@selector(bannerCustomEventWillExpandAd:) withObject:self];
    }
#pragma clang diagnostic pop
}

- (void)IAMRAIDContentController:(IAMRAIDContentController * _Nullable)contentController MRAIDAdDidExpandToFrame:(CGRect)frame {
    MPLogInfo(@"<Inneractive> MRAID ad did expand;");
}

- (void)IAMRAIDContentControllerMRAIDAdWillCollapse:(IAMRAIDContentController * _Nullable)contentController {
    MPLogInfo(@"<Inneractive> MRAID ad will collapse;");
}

- (void)IAMRAIDContentControllerMRAIDAdDidCollapse:(IAMRAIDContentController * _Nullable)contentController {
    MPLogInfo(@"<Inneractive> MRAID ad did collapse;");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self.delegate respondsToSelector:@selector(bannerCustomEventDidCollapseAd:)]) {
        [self.delegate performSelector:@selector(bannerCustomEventDidCollapseAd:) withObject:self];
    }
#pragma clang diagnostic pop
}

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
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], _mopubAdUnitID);
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], _mopubAdUnitID);
    MPLogDebug(@"%@ deallocated", NSStringFromClass(self.class));
}

@end
