//
//  InneractiveBannerCustomEvent.m
//  IASDKClient
//
//  Created by Inneractive 05/04/2017.
//  Copyright (c) 2017 Inneractive. All rights reserved.
//

#import "InneractiveBannerCustomEvent.h"

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

@property (nonatomic) BOOL isIABanner;

@end

@implementation InneractiveBannerCustomEvent {}

/**
 *  @brief Is called each time the MoPub SDK requires a new banner ad.
 *
 *  @discussion Also, when this method is invoked, this class is a new instance, it is not reused,
 * which makes call of this method only once per it's instance timelife.
 *
 *  @param size Ad size.
 *  @param info Info dictionary - a JSON object that is defined @MoPub console.
 */
- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info {
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
    MPAdView *adView = baseBannerAdapter.delegate.banner;
    
	IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
#warning In case of using ATS in order to allow only secure connections, please set to YES 'useSecureConnections' property:
		builder.useSecureConnections = NO;
        builder.spotID = spotID;
		builder.timeout = 15;
		builder.userData = userData;
        builder.keywords = adView.keywords;
        builder.location = self.delegate.location;
	}];
	
	_videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
		builder.videoContentDelegate = self;
	}];

	_MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {
		builder.MRAIDContentDelegate = self;
	}];

	_bannerUnitController = [IAViewUnitController build:^(id<IAViewUnitControllerBuilder>  _Nonnull builder) {
		builder.unitDelegate = self;
		
		[builder addSupportedContentController:self.videoContentController];
		[builder addSupportedContentController:self.MRAIDContentController];
	}];

	_adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
		builder.adRequest = request;
		[builder addSupportedUnitController:self.bannerUnitController];
		builder.mediationType = [IAMediationMopub new];
	}];
	
	__weak typeof(self) weakSelf = self; // a weak reference to 'self' should be used in the next block:

    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        if (error) {
            MPLogError(@"<Inneractive> ad failed with error: %@;", error);
			[weakSelf.delegate bannerCustomEvent:weakSelf didFailToLoadAdWithError:error];
        } else {
			if (adSpot.activeUnitController == weakSelf.bannerUnitController) {
                if (weakSelf.isIABanner && [adSpot.activeUnitController.activeContentController isKindOfClass:IAVideoContentController.class]) {
                    [weakSelf treatInternalError];
                } else {
					if (weakSelf.delegate.viewControllerForPresentingModalView.presentedViewController != nil) {
                        [weakSelf treatInternalError];
					} else {						
						weakSelf.bannerUnitController.adView.bounds = CGRectMake(0, 0, size.width, size.height);
                        MPLogInfo(@"<Inneractive> ad loaded;");
						[weakSelf.delegate bannerCustomEvent:weakSelf didLoadAd:weakSelf.bannerUnitController.adView];
					}
                }
			} else {
                [weakSelf treatInternalError];
			}
        }
    }];
}

#pragma mark - Service

- (void)treatInternalError {
    NSError *internalError = [NSError errorWithDomain:@"internal error" code:0 userInfo:nil];
    NSString *adFailMessage = [NSString stringWithFormat:@"<Inneractive> ad failed with: %@;", internalError.localizedDescription];
    
    MPLogError(@"%@", adFailMessage);
    [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:internalError];
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

#pragma mark - IAViewUnitControllerDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return self.delegate.viewControllerForPresentingModalView;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad clicked;");
    [self.delegate trackClick]; // manual track;
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad impression;");
    [self.delegate trackImpression]; // manual track;
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad will present fullscreen;");
    [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad did present fullscreen;");
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad will dismiss fullscreen;");
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> ad did dismiss fullscreen;");
    [self.delegate bannerCustomEventDidFinishAction:self];
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    MPLogInfo(@"<Inneractive> will open external app;");
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
}

- (void)IAMRAIDContentController:(IAMRAIDContentController * _Nullable)contentController MRAIDAdDidExpandToFrame:(CGRect)frame {
    MPLogInfo(@"<Inneractive> MRAID ad did expand;");
}

- (void)IAMRAIDContentControllerMRAIDAdWillCollapse:(IAMRAIDContentController * _Nullable)contentController {
    MPLogInfo(@"<Inneractive> MRAID ad will collapse;");
}

- (void)IAMRAIDContentControllerMRAIDAdDidCollapse:(IAMRAIDContentController * _Nullable)contentController {
    MPLogInfo(@"<Inneractive> MRAID ad did collapse;");
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
    MPLogDebug(@"%@ deallocated", NSStringFromClass(self.class));
}

@end
