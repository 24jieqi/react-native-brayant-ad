//
//  PangleAdModule.m
//  Zhiya
//

#import "PangleAdModule.h"
#import "ATTPermissionService.h"
#import "BannerAd.h"
#import "ExpressNativeAd.h"
#import "InterstitialAd.h"
#import "PAGSDKService.h"
#import "SplashAd.h"
#import <React/RCTLog.h>
#import <React/RCTUIManager.h>

NSString *const PangleInterstitialAdLoaded = @"PangleInterstitialAdLoaded";
NSString *const PangleInterstitialAdLoadFail = @"PangleInterstitialAdLoadFail";
NSString *const PangleInterstitialAdShowed = @"PangleInterstitialAdShowed";
NSString *const PangleInterstitialAdClicked = @"PangleInterstitialAdClicked";
NSString *const PangleInterstitialAdClosed = @"PangleInterstitialAdClosed";

NSString *const PangleBannerAdLoaded = @"PangleBannerAdLoaded";
NSString *const PangleBannerAdLoadFail = @"PangleBannerAdLoadFail";
NSString *const PangleBannerAdRenderSuccess = @"PangleBannerAdRenderSuccess";
NSString *const PangleBannerAdShowed = @"PangleBannerAdShowed";
NSString *const PangleBannerAdClicked = @"PangleBannerAdClicked";
NSString *const PangleBannerAdClosed = @"PangleBannerAdClosed";

NSString *const PangleExpressNativeAdLoaded = @"PangleExpressNativeAdLoaded";
NSString *const PangleExpressNativeAdLoadFail =
    @"PangleExpressNativeAdLoadFail";
NSString *const PangleExpressNativeAdRenderSuccess =
    @"PangleExpressNativeAdRenderSuccess";
NSString *const PangleExpressNativeAdClicked = @"PangleExpressNativeAdClicked";
NSString *const PangleExpressNativeAdClosed = @"PangleExpressNativeAdClosed";

NSString *const PangleFeedAdLoaded = @"PangleFeedAdLoaded";
NSString *const PangleFeedAdLoadFail = @"PangleFeedAdLoadFail";
NSString *const PangleFeedAdRenderSuccess = @"PangleFeedAdRenderSuccess";
NSString *const PangleFeedAdClicked = @"PangleFeedAdClicked";
NSString *const PangleFeedAdClosed = @"PangleFeedAdClosed";
NSString *const PangleFeedAdError = @"PangleFeedAdError";
NSString *const PangleFeedAdLayout = @"PangleFeedAdLayout";

void Zhiya_notifyAdReady(void);
void Zhiya_notifyAdSkipped(void);
void Zhiya_notifyAdClosed(void);

@interface PangleAdModule ()

@property(nonatomic, assign) BOOL hasListeners;

@end

@implementation PangleAdModule

static __weak PangleAdModule *sCurrentInstance = nil;
static BOOL sPendingSplashAdClosedEvent = NO;

+ (instancetype)sharedInstance {
  if (sCurrentInstance) {
    return sCurrentInstance;
  }
  return [[PangleAdModule alloc] init];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    sCurrentInstance = self;
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleNotification:(NSNotification *)notification {
  NSString *eventName = notification.name;
  id body = notification.object;
  if (self.hasListeners) {
    [self sendEventWithName:eventName body:body];
    return;
  }

  if ([eventName isEqualToString:@"PangleSplashAdClosed"]) {
    sPendingSplashAdClosedEvent = YES;
  }
}

- (void)notifyAdClosed {
  dispatch_async(dispatch_get_main_queue(), ^{
    Zhiya_notifyAdClosed();

    if (self.bridge != nil && self.hasListeners) {
      [self sendEventWithName:@"PangleSplashAdClosed" body:nil];
    } else {
      sPendingSplashAdClosedEvent = YES;
    }
  });
}

RCT_EXPORT_METHOD(flushPendingAdClosedEvent) {
  if (sPendingSplashAdClosedEvent && self.bridge != nil && self.hasListeners) {
    sPendingSplashAdClosedEvent = NO;
    [self sendEventWithName:@"PangleSplashAdClosed" body:nil];
  }
}

- (NSArray<NSString *> *)supportedEvents {
  return @[
    @"PangleSplashAdClosed",
    PangleInterstitialAdLoaded,
    PangleInterstitialAdLoadFail,
    PangleInterstitialAdShowed,
    PangleInterstitialAdClicked,
    PangleInterstitialAdClosed,
    PangleBannerAdLoaded,
    PangleBannerAdLoadFail,
    PangleBannerAdRenderSuccess,
    PangleBannerAdShowed,
    PangleBannerAdClicked,
    PangleBannerAdClosed,
    PangleExpressNativeAdLoaded,
    PangleExpressNativeAdLoadFail,
    PangleExpressNativeAdRenderSuccess,
    PangleExpressNativeAdClicked,
    PangleExpressNativeAdClosed,
    PangleFeedAdLoaded,
    PangleFeedAdLoadFail,
    PangleFeedAdRenderSuccess,
    PangleFeedAdClicked,
    PangleFeedAdClosed,
    PangleFeedAdError,
    PangleFeedAdLayout,
  ];
}

- (void)startObserving {
  self.hasListeners = YES;

  NSArray *events = [self supportedEvents];
  for (NSString *event in events) {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(handleNotification:)
               name:event
             object:nil];
  }

  if (sPendingSplashAdClosedEvent) {
    sPendingSplashAdClosedEvent = NO;
    [self sendEventWithName:@"PangleSplashAdClosed" body:nil];
  }
}

- (void)stopObserving {
  self.hasListeners = NO;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

RCT_EXPORT_MODULE(PangleAdModule)

RCT_EXPORT_METHOD(initialize : (NSString *)appID resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  [[PAGSDKService sharedService]
      initializeSDKWithAppID:appID
                  completion:^(BOOL success, NSError *_Nullable error) {
                    if (success) {
                      resolve(@{
                        @"success" : @YES,
                        @"version" : [[PAGSDKService sharedService] SDKVersion]
                      });
                    } else {
                      reject(@"INIT_ERROR", error.localizedDescription, error);
                    }
                  }];
}

RCT_EXPORT_METHOD(isSDKInitialized : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  BOOL initialized = [[PAGSDKService sharedService] isInitialized];
  resolve(@(initialized));
}

RCT_EXPORT_METHOD(loadSplashAd : (NSString *)slotID) {
  [[SplashAd sharedInstance] loadAdWithSlotID:slotID];
}

RCT_EXPORT_METHOD(isSplashAdReady : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  BOOL ready = [[SplashAd sharedInstance] isAdReady];
  resolve(@(ready));
}

RCT_EXPORT_METHOD(showSplashAd : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  UIViewController *rootVC = [self rootViewController];
  if (!rootVC) {
    reject(@"NO_VIEW_CONTROLLER", @"无法找到根视图控制器", nil);
    return;
  }

  [[SplashAd sharedInstance]
      showAdInRootViewController:rootVC
                      onComplete:^(BOOL completed, NSError *_Nullable error) {
                        if (completed) {
                          resolve(@{@"completed" : @YES});
                        } else if (error) {
                          reject(@"AD_ERROR", error.localizedDescription,
                                 error);
                        } else {
                          resolve(@{@"completed" : @NO});
                        }
                      }];
}

RCT_EXPORT_METHOD(getATTStatus : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  ATTAuthorizationStatus status =
      [[ATTPermissionService sharedService] currentStatus];
  resolve(@{
    @"status" : @(status),
    @"notDetermined" : @(status == ATTAuthorizationStatusNotDetermined),
    @"restricted" : @(status == ATTAuthorizationStatusRestricted),
    @"denied" : @(status == ATTAuthorizationStatusDenied),
    @"authorized" : @(status == ATTAuthorizationStatusAuthorized)
  });
}

RCT_EXPORT_METHOD(requestATT : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  [[ATTPermissionService sharedService]
      requestAuthorizationWithCompletion:^(BOOL granted) {
        resolve(@{@"granted" : @(granted)});
      }];
}

RCT_EXPORT_METHOD(notifyAdReady) {
  Zhiya_notifyAdReady();
}

RCT_EXPORT_METHOD(notifyAdSkipped) { Zhiya_notifyAdSkipped(); }

#pragma mark - Interstitial Ad

RCT_EXPORT_METHOD(loadInterstitialAd : (NSString *)slotID) {
  [[InterstitialAd sharedInstance] loadAdWithSlotID:slotID];
}

RCT_EXPORT_METHOD(isInterstitialAdReady : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  BOOL ready = [[InterstitialAd sharedInstance] isAdReady];
  resolve(@(ready));
}

RCT_EXPORT_METHOD(showInterstitialAd : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  UIViewController *rootVC = [self rootViewController];
  if (!rootVC) {
    reject(@"NO_VIEW_CONTROLLER", @"无法找到根视图控制器", nil);
    return;
  }

  [[InterstitialAd sharedInstance]
      showAdInRootViewController:rootVC
                      onComplete:^(BOOL completed, NSError *_Nullable error) {
                        if (completed) {
                          resolve(@{@"completed" : @YES});
                        } else if (error) {
                          reject(@"AD_ERROR", error.localizedDescription,
                                 error);
                        } else {
                          resolve(@{@"completed" : @NO});
                        }
                      }];
}

RCT_EXPORT_METHOD(removeInterstitialAd) {
  [[InterstitialAd sharedInstance] removeAd];
}

#pragma mark - Banner Ad

RCT_EXPORT_METHOD(loadBannerAd : (NSString *)slotID sizeType : (NSInteger)
                      sizeType) {
  [[BannerAd sharedInstance] loadAdWithSlotID:slotID
                                     sizeType:(BannerAdSizeType)sizeType];
}

RCT_EXPORT_METHOD(loadBannerAdWithSize : (NSString *)slotID sizeType : (
    NSInteger)sizeType width : (double)width height : (double)height) {
  [[BannerAd sharedInstance] loadAdWithSlotID:slotID
                                     sizeType:(BannerAdSizeType)sizeType
                                        width:width
                                       height:height];
}

RCT_EXPORT_METHOD(showBannerAd : (nonnull NSNumber *)reactTag resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTUIManager *uiManager = self.bridge.uiManager;
    UIView *containerView = [uiManager viewForReactTag:reactTag];

    if (!containerView) {
      reject(@"NO_VIEW", @"无法找到容器视图", nil);
      return;
    }

    [[BannerAd sharedInstance] showInView:containerView];
    resolve(@{@"success" : @YES});
  });
}

RCT_EXPORT_METHOD(hideBannerAd : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  [[BannerAd sharedInstance] hide];
  resolve(@{@"success" : @YES});
}

RCT_EXPORT_METHOD(removeBannerAd) { [[BannerAd sharedInstance] removeAd]; }

RCT_EXPORT_METHOD(setBannerRefreshInterval : (double)interval) {
  [BannerAd sharedInstance].refreshInterval = interval;
}

#pragma mark - Express Native Ad

RCT_EXPORT_METHOD(loadExpressNativeAd : (NSString *)slotID) {
  [[ExpressNativeAd sharedInstance] loadAdWithSlotID:slotID width:0 height:0];
}

RCT_EXPORT_METHOD(loadExpressNativeAdWithAdSize : (NSString *)
                      slotID width : (CGFloat)width height : (CGFloat)height) {
  [[ExpressNativeAd sharedInstance] loadAdWithSlotID:slotID
                                               width:width
                                              height:height];
}

RCT_EXPORT_METHOD(isExpressNativeAdReady : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  BOOL ready = [[ExpressNativeAd sharedInstance] isAdReady];
  resolve(@(ready));
}

RCT_EXPORT_METHOD(registerExpressNativeAdContainer : (NSString *)containerRef) {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIView *containerView = [self viewForTag:[containerRef integerValue]];
    if (containerView) {
      [[ExpressNativeAd sharedInstance] registerContainerView:containerView];
    }
  });
}

RCT_EXPORT_METHOD(unregisterExpressNativeAdView) {
  // Express Native Ad views are managed by the SDK
}

- (UIView *)viewForTag:(NSInteger)tag {
  if (!self.bridge) {
    return nil;
  }
  RCTUIManager *uiManager =
      (RCTUIManager *)[self.bridge moduleForClass:[RCTUIManager class]];
  if (!uiManager) {
    return nil;
  }
  return [uiManager viewForReactTag:@(tag)];
}

- (UIViewController *)rootViewController {
  return RCTPresentedViewController();
}

@end
