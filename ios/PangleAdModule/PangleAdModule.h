//
//  PangleAdModule.h
//  Zhiya
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const PangleSplashAdLoadFail;

extern NSString * const PangleInterstitialAdLoaded;
extern NSString * const PangleInterstitialAdLoadFail;
extern NSString * const PangleInterstitialAdShowed;
extern NSString * const PangleInterstitialAdClicked;
extern NSString * const PangleInterstitialAdClosed;

extern NSString * const PangleBannerAdLoaded;
extern NSString * const PangleBannerAdLoadFail;
extern NSString * const PangleBannerAdRenderSuccess;
extern NSString * const PangleBannerAdShowed;
extern NSString * const PangleBannerAdClicked;
extern NSString * const PangleBannerAdClosed;

extern NSString * const PangleExpressNativeAdLoaded;
extern NSString * const PangleExpressNativeAdLoadFail;
extern NSString * const PangleExpressNativeAdRenderSuccess;
extern NSString * const PangleExpressNativeAdClicked;
extern NSString * const PangleExpressNativeAdClosed;

extern NSString * const PangleFeedAdLoaded;
extern NSString * const PangleFeedAdLoadFail;
extern NSString * const PangleFeedAdRenderSuccess;
extern NSString * const PangleFeedAdClicked;
extern NSString * const PangleFeedAdClosed;
extern NSString * const PangleFeedAdError;
extern NSString * const PangleFeedAdLayout;

@interface PangleAdModule : RCTEventEmitter

+ (instancetype)sharedInstance;
- (NSArray<NSString *> *)supportedEvents;
- (void)notifyAdClosed;
- (void)flushPendingAdClosedEvent;

@end

NS_ASSUME_NONNULL_END
