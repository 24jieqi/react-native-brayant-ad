//
//  PangleAdModule.m
//  Zhiya
//

#import "PangleAdModule.h"
#import "AdResourceStore.h"
#import "ATTPermissionService.h"
#import "BannerAd.h"
#import "ExpressNativeAd.h"
#import "InterstitialAd.h"
#import "PAGSDKService.h"
#import "RewardedAd.h"
#import "SplashAd.h"
#import <React/RCTLog.h>
#import <React/RCTUIManager.h>

NSString *const PangleSplashAdLoadFail = @"PangleSplashAdLoadFail";

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

@interface PangleAdModule ()

@property(nonatomic, assign) BOOL hasListeners;
@property(nonatomic, strong) SplashAd *splashAd;
@property(nonatomic, strong) BannerAd *legacyBannerAd;
@property(nonatomic, strong) ExpressNativeAd *legacyExpressNativeAd;
@property(nonatomic, copy, nullable) NSString *activeFullscreenRequestId;
- (NSDictionary *)tokenPayload:(AdResourceEntry *)entry;
- (void)emitV2EventForRequest:(NSString *)requestId
                       format:(NSString *)format
                       slotId:(NSString *)slotId
                        state:(NSString *)state
                       source:(NSString *)source
                    startedAt:(NSTimeInterval)startedAt
                        error:(nullable NSError *)error;

@end

@implementation PangleAdModule

- (instancetype)init {
  self = [super init];
  if (self) {
    _splashAd = [[SplashAd alloc] init];
    _legacyBannerAd = [[BannerAd alloc] init];
    _legacyExpressNativeAd = [[ExpressNativeAd alloc] init];
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
  }
}

RCT_EXPORT_METHOD(addListener : (NSString *)eventName) {
  [super addListener:eventName];
}

RCT_EXPORT_METHOD(removeListeners : (double)count) {
  [super removeListeners:count];
}

- (NSArray<NSString *> *)supportedEvents {
  return @[
    PangleSplashAdLoadFail,
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
    @"BrayantAd-onEvent",
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

RCT_EXPORT_METHOD(initializeAdSdk : (NSDictionary *)config resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  if (config[@"allowInitialization"] &&
      ![config[@"allowInitialization"] boolValue]) {
    resolve(@NO);
    return;
  }
  NSString *appId = config[@"appId"];
  if (!appId || appId.length == 0) {
    reject(@"INVALID_APP_ID", @"appId 不能为空", nil);
    return;
  }
  [[PAGSDKService sharedService]
      initializeSDKWithAppID:appId
                  completion:^(BOOL success, NSError *_Nullable error) {
                    if (success) {
                      resolve(@YES);
                    } else {
                      reject(@"INIT_ERROR", error.localizedDescription, error);
                    }
                  }];
}

RCT_EXPORT_METHOD(preloadAd : (NSDictionary *)request resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  NSString *requestId = request[@"requestId"];
  NSString *format = request[@"format"];
  NSArray<NSString *> *slotIds = request[@"slotIds"];
  NSString *slotId = slotIds.firstObject;
  NSDictionary *size = request[@"size"];
  double width = [size[@"width"] doubleValue];
  double height = [size[@"height"] doubleValue];

  if (!requestId || !format || !slotId) {
    reject(@"INVALID_REQUEST", @"广告请求缺少必要字段", nil);
    return;
  }

  if ([format isEqualToString:@"feed"]) {
    ExpressNativeAd *ad = [[ExpressNativeAd alloc] init];
    [ad loadAdWithSlotID:slotId
                   width:width
                  height:height
              completion:^(BOOL success, NSError *_Nullable error) {
                if (!success) {
                  reject(@"PRELOAD_FAILED", error.localizedDescription, error);
                  return;
                }
                AdResourceEntry *entry =
                    [[AdResourceStore sharedStore] storeResource:ad
                                                      requestId:requestId
                                                         format:format
                                                         slotId:slotId
                                                          width:width
                                                         height:height];
                resolve([self tokenPayload:entry]);
              }];
    return;
  }

  if ([format isEqualToString:@"banner"]) {
    BannerAd *ad = [[BannerAd alloc] init];
    double effectiveHeight = height > 0 ? height : 50;
    [ad loadAdWithSlotID:slotId
                sizeType:BannerAdSizeTypeFixed
                   width:width
                  height:effectiveHeight
              completion:^(BOOL success, NSError *_Nullable error) {
                if (!success) {
                  reject(@"PRELOAD_FAILED", error.localizedDescription, error);
                  return;
                }
                AdResourceEntry *entry =
                    [[AdResourceStore sharedStore] storeResource:ad
                                                      requestId:requestId
                                                         format:format
                                                         slotId:slotId
                                                          width:width
                                                         height:effectiveHeight];
                resolve([self tokenPayload:entry]);
              }];
    return;
  }

  if ([format isEqualToString:@"splash"]) {
    SplashAd *ad = [[SplashAd alloc] init];
    [ad loadAdWithSlotID:slotId
              completion:^(BOOL success, NSError *_Nullable error) {
                if (!success) {
                  reject(@"PRELOAD_FAILED", error.localizedDescription, error);
                  return;
                }
                AdResourceEntry *entry =
                    [[AdResourceStore sharedStore] storeResource:ad
                                                      requestId:requestId
                                                         format:format
                                                         slotId:slotId
                                                          width:width
                                                         height:height];
                resolve([self tokenPayload:entry]);
              }];
    return;
  }

  if ([format isEqualToString:@"rewarded"]) {
    NSDictionary *reward = request[@"reward"];
    RewardedAd *ad = [[RewardedAd alloc] init];
    [ad loadAdWithSlotID:slotId
                  userId:reward[@"userId"]
              rewardName:reward[@"rewardName"]
            rewardAmount:reward[@"rewardAmount"]
                   extra:reward[@"extra"]
              completion:^(BOOL success, NSError *_Nullable error) {
                if (!success) {
                  reject(@"PRELOAD_FAILED",
                         error.localizedDescription ?: @"激励视频预加载失败",
                         error);
                  return;
                }
                AdResourceEntry *entry =
                    [[AdResourceStore sharedStore] storeResource:ad
                                                      requestId:requestId
                                                         format:format
                                                         slotId:slotId
                                                          width:0
                                                         height:0];
                resolve([self tokenPayload:entry]);
              }];
    return;
  }

  if ([format isEqualToString:@"interstitial"]) {
    InterstitialAd *ad = [[InterstitialAd alloc] init];
    [ad loadAdWithSlotID:slotId
              completion:^(BOOL success, NSError *_Nullable error) {
                if (!success) {
                  reject(@"PRELOAD_FAILED",
                         error.localizedDescription ?: @"插屏广告预加载失败",
                         error);
                  return;
                }
                AdResourceEntry *entry =
                    [[AdResourceStore sharedStore] storeResource:ad
                                                      requestId:requestId
                                                         format:format
                                                         slotId:slotId
                                                          width:0
                                                         height:0];
                resolve([self tokenPayload:entry]);
              }];
    return;
  }

  reject(@"UNSUPPORTED_FORMAT", format, nil);
}

RCT_EXPORT_METHOD(showSplashAdV2 : (NSDictionary *)params resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  NSDictionary *request = params[@"request"];
  NSString *requestId = request[@"requestId"];
  NSArray<NSString *> *slotIds = request[@"slotIds"];
  NSString *slotId = slotIds.firstObject;
  NSDictionary *size = request[@"size"];
  double width = [size[@"width"] doubleValue];
  double height = [size[@"height"] doubleValue];
  NSDictionary *tokenPayload = params[@"preloadToken"];
  NSString *token = tokenPayload[@"token"];
  NSTimeInterval timeoutMs = [params[@"timeoutMs"] doubleValue];
  NSTimeInterval startedAt = [NSDate date].timeIntervalSince1970;
  UIViewController *rootVC = [self rootViewController];

  if (!requestId || !slotId || !rootVC) {
    reject(@"INVALID_REQUEST", @"开屏广告请求或根控制器无效", nil);
    return;
  }

  __block BOOL settled = NO;
  __block SplashAd *activeAd = nil;
  void (^finish)(NSString *, NSError *) = ^(NSString *status, NSError *error) {
    if (settled) {
      return;
    }
    settled = YES;
    NSTimeInterval elapsed =
        ([NSDate date].timeIntervalSince1970 - startedAt) * 1000;
    NSMutableDictionary *result = [@{
      @"requestId" : requestId,
      @"slotId" : slotId,
      @"status" : status,
      @"elapsedMs" : @(elapsed),
    } mutableCopy];
    if (error) {
      result[@"error"] = @{
        @"code" : @"SPLASH_ERROR",
        @"message" : error.localizedDescription ?: @"开屏广告失败",
        @"nativeCode" : @(error.code),
      };
    }
    resolve(result);
  };

  void (^showLoaded)(SplashAd *, NSString *) =
      ^(SplashAd *ad, NSString *source) {
        activeAd = ad;
        ad.eventHandler = ^(NSString *state, NSError *error) {
          [self emitV2EventForRequest:requestId
                              format:@"splash"
                              slotId:slotId
                               state:state
                              source:source
                           startedAt:startedAt
                               error:error];
        };
        [ad showAdInRootViewController:rootVC
                           onComplete:^(BOOL completed, NSError *error) {
                             finish(completed ? @"closed" : @"failed", error);
                           }];
      };

  AdResourceEntry *entry =
      [[AdResourceStore sharedStore] consumeToken:token
                                          format:@"splash"
                                          slotId:slotId
                                           width:width
                                          height:height];
  if (entry && [entry.resource isKindOfClass:[SplashAd class]]) {
    showLoaded((SplashAd *)entry.resource, @"preloaded");
  } else {
    SplashAd *ad = [[SplashAd alloc] init];
    activeAd = ad;
    [ad loadAdWithSlotID:slotId
              completion:^(BOOL success, NSError *_Nullable error) {
                if (!success) {
                  finish(@"failed", error);
                  return;
                }
                showLoaded(ad, @"realtime");
              }];
  }

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(MAX(timeoutMs, 1000) / 1000.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        if (!settled) {
          [activeAd removeAd];
          finish(@"skipped", nil);
        }
      });
}

RCT_EXPORT_METHOD(showFullscreenAdV2 : (NSDictionary *)params resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  NSDictionary *request = params[@"request"];
  NSString *requestId = request[@"requestId"];
  NSString *format = request[@"format"];
  NSArray<NSString *> *slotIds = request[@"slotIds"];
  NSString *slotId = slotIds.firstObject;
  NSDictionary *tokenPayload = params[@"preloadToken"];
  NSString *token = tokenPayload[@"token"];
  NSTimeInterval loadTimeoutMs = [params[@"loadTimeoutMs"] doubleValue];
  UIViewController *rootVC = [self rootViewController];

  if (!requestId || !slotId ||
      (!([format isEqualToString:@"rewarded"] ||
         [format isEqualToString:@"interstitial"]))) {
    reject(@"INVALID_REQUEST", @"全屏广告请求无效", nil);
    return;
  }

  NSDictionary *(^errorPayload)(NSString *, NSString *, NSError *, NSString *) =
      ^NSDictionary *(NSString *code, NSString *message, NSError *nativeError,
                      NSString *stage) {
        NSMutableDictionary *payload = [@{
          @"code" : code,
          @"message" : message ?: code,
        } mutableCopy];
        if (nativeError) payload[@"nativeCode"] = @(nativeError.code);
        if (stage) payload[@"stage"] = stage;
        return payload;
      };

  if (!rootVC) {
    resolve(@{
      @"requestId" : requestId,
      @"slotId" : slotId,
      @"status" : @"failed",
      @"elapsedMs" : @0,
      @"presented" : @NO,
      @"videoCompleted" : @NO,
      @"error" : errorPayload(@"VIEW_CONTROLLER_UNAVAILABLE",
                               @"当前视图控制器不可用", nil, @"show"),
    });
    return;
  }

  @synchronized(self) {
    if (self.activeFullscreenRequestId) {
      resolve(@{
        @"requestId" : requestId,
        @"slotId" : slotId,
        @"status" : @"cancelled",
        @"elapsedMs" : @0,
        @"presented" : @NO,
        @"videoCompleted" : @NO,
        @"error" : errorPayload(@"FULLSCREEN_BUSY",
                                 @"已有全屏广告正在展示", nil, nil),
      });
      return;
    }
    self.activeFullscreenRequestId = requestId;
  }

  NSTimeInterval startedAt = [NSDate date].timeIntervalSince1970;
  AdResourceEntry *entry =
      [[AdResourceStore sharedStore] consumeToken:token
                                          format:format
                                          slotId:slotId
                                           width:0
                                          height:0];
  NSString *source = entry ? @"preloaded" : @"realtime";
  __block BOOL settled = NO;
  __block BOOL loadFinished = entry != nil;
  __block BOOL presented = NO;
  __block BOOL videoCompleted = NO;
  __block BOOL skipped = NO;
  __block NSDictionary *rewardPayload = nil;

  void (^emit)(NSString *, NSString *, NSDictionary *, NSDictionary *) =
      ^(NSString *state, NSString *action, NSDictionary *error,
        NSDictionary *reward) {
        if (!self.hasListeners) return;
        NSTimeInterval elapsed =
            ([NSDate date].timeIntervalSince1970 - startedAt) * 1000;
        NSMutableDictionary *payload = [@{
          @"requestId" : requestId,
          @"format" : format,
          @"slotId" : slotId,
          @"state" : state,
          @"source" : source,
          @"elapsedMs" : @(elapsed),
        } mutableCopy];
        if (action) payload[@"action"] = action;
        if (error) payload[@"error"] = error;
        if (reward) payload[@"reward"] = reward;
        [self sendEventWithName:@"BrayantAd-onEvent" body:payload];
      };

  void (^finish)(NSString *, NSDictionary *) =
      ^(NSString *status, NSDictionary *error) {
        @synchronized(self) {
          if (settled) return;
          settled = YES;
          if ([self.activeFullscreenRequestId isEqualToString:requestId]) {
            self.activeFullscreenRequestId = nil;
          }
        }
        emit(@"terminal", nil, error, nil);
        NSTimeInterval elapsed =
            ([NSDate date].timeIntervalSince1970 - startedAt) * 1000;
        NSMutableDictionary *result = [@{
          @"requestId" : requestId,
          @"slotId" : slotId,
          @"status" : status,
          @"elapsedMs" : @(elapsed),
          @"presented" : @(presented),
          @"videoCompleted" : @(videoCompleted),
        } mutableCopy];
        if (error) result[@"error"] = error;
        if (rewardPayload) result[@"reward"] = rewardPayload;
        resolve(result);
      };

  void (^showRewarded)(RewardedAd *) = ^(RewardedAd *ad) {
    ad.eventHandler = ^(NSString *event, NSError *error) {
      if ([event isEqualToString:@"presented"]) {
        presented = YES;
        emit(@"presented", nil, nil, nil);
      } else if ([event isEqualToString:@"click"]) {
        emit(@"presented", @"click", nil, nil);
      } else if ([event isEqualToString:@"skip"]) {
        skipped = YES;
        emit(@"presented", @"skip", nil, nil);
      } else if ([event isEqualToString:@"video-complete"]) {
        videoCompleted = YES;
        emit(@"presented", @"video-complete", nil, nil);
      } else if ([event isEqualToString:@"playback-failed"] ||
                 [event isEqualToString:@"failed"]) {
        finish(@"failed",
               errorPayload(@"AD_PLAYBACK_FAILED",
                            error.localizedDescription ?: @"激励视频播放失败",
                            error, @"playback"));
      }
    };
    ad.verificationHandler =
        ^(BOOL valid, NSDictionary *reward, NSError *error) {
          NSMutableDictionary *normalized = [reward mutableCopy];
          if (error || !valid) {
            normalized[@"error"] = errorPayload(
                @"REWARD_INVALID",
                error.localizedDescription ?: @"奖励校验未通过", error,
                @"playback");
          }
          rewardPayload = normalized;
          emit(@"presented", @"reward", nil, normalized);
        };
    [ad showAdInRootViewController:rootVC
                        completion:^(BOOL completed, NSError *error) {
                          if (!completed || error) {
                            finish(@"failed",
                                   errorPayload(
                                       @"AD_SHOW_FAILED",
                                       error.localizedDescription ?:
                                           @"激励视频展示失败",
                                       error, @"show"));
                            return;
                          }
                          finish(skipped ? @"skipped" : @"closed", nil);
                        }];
  };

  void (^showInterstitial)(InterstitialAd *) = ^(InterstitialAd *ad) {
    ad.eventHandler = ^(NSString *event, NSError *error) {
      if ([event isEqualToString:@"presented"]) {
        presented = YES;
        emit(@"presented", nil, nil, nil);
      } else if ([event isEqualToString:@"click"]) {
        emit(@"presented", @"click", nil, nil);
      } else if ([event isEqualToString:@"skip"]) {
        skipped = YES;
        emit(@"presented", @"skip", nil, nil);
      } else if ([event isEqualToString:@"video-complete"]) {
        videoCompleted = YES;
        emit(@"presented", @"video-complete", nil, nil);
      } else if ([event isEqualToString:@"playback-failed"] ||
                 [event isEqualToString:@"failed"]) {
        finish(@"failed",
               errorPayload(@"AD_PLAYBACK_FAILED",
                            error.localizedDescription ?: @"插屏广告播放失败",
                            error, @"playback"));
      }
    };
    [ad showAdInRootViewController:rootVC
                        onComplete:^(BOOL completed, NSError *error) {
                          if (!completed || error) {
                            finish(@"failed",
                                   errorPayload(
                                       @"AD_SHOW_FAILED",
                                       error.localizedDescription ?:
                                           @"插屏广告展示失败",
                                       error, @"show"));
                            return;
                          }
                          finish(skipped ? @"skipped" : @"closed", nil);
                        }];
  };

  if ([format isEqualToString:@"rewarded"]) {
    if ([entry.resource isKindOfClass:[RewardedAd class]]) {
      emit(@"loaded", nil, nil, nil);
      showRewarded((RewardedAd *)entry.resource);
    } else {
      NSDictionary *reward = request[@"reward"];
      RewardedAd *ad = [[RewardedAd alloc] init];
      emit(@"loading", nil, nil, nil);
      [ad loadAdWithSlotID:slotId
                    userId:reward[@"userId"]
                rewardName:reward[@"rewardName"]
              rewardAmount:reward[@"rewardAmount"]
                     extra:reward[@"extra"]
                completion:^(BOOL success, NSError *error) {
                  if (settled) return;
                  if (!success) {
                    finish(@"failed",
                           errorPayload(
                               @"AD_LOAD_FAILED",
                               error.localizedDescription ?:
                                   @"激励视频加载失败",
                               error, @"load"));
                    return;
                  }
                  loadFinished = YES;
                  emit(@"loaded", nil, nil, nil);
                  showRewarded(ad);
                }];
    }
  } else if ([entry.resource isKindOfClass:[InterstitialAd class]]) {
    emit(@"loaded", nil, nil, nil);
    showInterstitial((InterstitialAd *)entry.resource);
  } else {
    InterstitialAd *ad = [[InterstitialAd alloc] init];
    emit(@"loading", nil, nil, nil);
    [ad loadAdWithSlotID:slotId
              completion:^(BOOL success, NSError *error) {
                if (settled) return;
                if (!success) {
                  finish(@"failed",
                         errorPayload(@"AD_LOAD_FAILED",
                                      error.localizedDescription ?:
                                          @"插屏广告加载失败",
                                      error, @"load"));
                  return;
                }
                loadFinished = YES;
                emit(@"loaded", nil, nil, nil);
                showInterstitial(ad);
              }];
  }

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(MAX(loadTimeoutMs, 1) / 1000.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        if (!settled && !loadFinished) {
          finish(@"failed",
                 errorPayload(@"AD_LOAD_TIMEOUT", @"广告加载超时", nil,
                              @"load"));
        }
      });
}

RCT_EXPORT_METHOD(loadSplashAd : (NSString *)slotID) {
  __weak typeof(self) weakSelf = self;
  self.splashAd.eventHandler = ^(NSString *state, NSError *error) {
    if ([state isEqualToString:@"closed"] && weakSelf.hasListeners) {
      [weakSelf sendEventWithName:@"PangleSplashAdClosed" body:nil];
    }
  };
  [self.splashAd loadAdWithSlotID:slotID];
}

RCT_EXPORT_METHOD(isSplashAdReady : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  BOOL ready = [self.splashAd isAdReady];
  resolve(@(ready));
}

RCT_EXPORT_METHOD(showSplashAd : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  UIViewController *rootVC = [self rootViewController];
  if (!rootVC) {
    reject(@"NO_VIEW_CONTROLLER", @"无法找到根视图控制器", nil);
    return;
  }

  [self.splashAd
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
  [self.legacyBannerAd loadAdWithSlotID:slotID
                               sizeType:(BannerAdSizeType)sizeType];
}

RCT_EXPORT_METHOD(loadBannerAdWithSize : (NSString *)slotID sizeType : (
    NSInteger)sizeType width : (double)width height : (double)height) {
  [self.legacyBannerAd loadAdWithSlotID:slotID
                               sizeType:(BannerAdSizeType)sizeType
                                  width:width
                                 height:height];
}

RCT_EXPORT_METHOD(isBannerAdReadyWithSize : (NSString *)slotID sizeType : (
    NSInteger)sizeType width : (double)width height : (double)height resolver : (
    RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject) {
  BOOL ready = [self.legacyBannerAd
      isReadyForSlotID:slotID
              sizeType:(BannerAdSizeType)sizeType
                 width:width
                height:height];
  resolve(@(ready));
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

    [self.legacyBannerAd showInView:containerView];
    resolve(@{@"success" : @YES});
  });
}

RCT_EXPORT_METHOD(hideBannerAd : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  [self.legacyBannerAd hide];
  resolve(@{@"success" : @YES});
}

RCT_EXPORT_METHOD(removeBannerAd) { [self.legacyBannerAd removeAd]; }

RCT_EXPORT_METHOD(setBannerRefreshInterval : (double)interval) {
  self.legacyBannerAd.refreshInterval = interval;
}

#pragma mark - Express Native Ad

RCT_EXPORT_METHOD(loadExpressNativeAd : (NSString *)slotID) {
  [self.legacyExpressNativeAd loadAdWithSlotID:slotID width:0 height:0];
}

RCT_EXPORT_METHOD(loadExpressNativeAdWithAdSize : (NSString *)
                      slotID width : (CGFloat)width height : (CGFloat)height) {
  [self.legacyExpressNativeAd loadAdWithSlotID:slotID
                                         width:width
                                        height:height];
}

RCT_EXPORT_METHOD(isExpressNativeAdReady : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject) {
  BOOL ready = [self.legacyExpressNativeAd isAdReady];
  resolve(@(ready));
}

RCT_EXPORT_METHOD(registerExpressNativeAdContainer : (NSString *)containerRef) {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIView *containerView = [self viewForTag:[containerRef integerValue]];
    if (containerView) {
      [self.legacyExpressNativeAd registerContainerView:containerView];
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

- (NSDictionary *)tokenPayload:(AdResourceEntry *)entry {
  return @{
    @"token" : entry.token,
    @"requestId" : entry.requestId,
    @"format" : entry.format,
    @"slotId" : entry.slotId,
    @"expiresAt" : @(entry.expiresAt * 1000),
  };
}

- (void)emitV2EventForRequest:(NSString *)requestId
                       format:(NSString *)format
                       slotId:(NSString *)slotId
                        state:(NSString *)state
                       source:(NSString *)source
                    startedAt:(NSTimeInterval)startedAt
                        error:(NSError *)error {
  if (!self.hasListeners) {
    return;
  }
  NSTimeInterval elapsed =
      ([NSDate date].timeIntervalSince1970 - startedAt) * 1000;
  NSMutableDictionary *payload = [@{
    @"requestId" : requestId,
    @"format" : format,
    @"slotId" : slotId,
    @"state" : state,
    @"source" : source,
    @"elapsedMs" : @(elapsed),
  } mutableCopy];
  if (error) {
    payload[@"error"] = @{
      @"code" : @"AD_ERROR",
      @"message" : error.localizedDescription ?: @"广告失败",
      @"nativeCode" : @(error.code),
    };
  }
  [self sendEventWithName:@"BrayantAd-onEvent" body:payload];
}

- (UIViewController *)rootViewController {
  return RCTPresentedViewController();
}

@end
