#import "BrayantBannerAdView.h"
#import "AdResourceStore.h"
#import "BannerAd.h"

@interface BrayantBannerAdView () <BannerAdDelegate>
@property(nonatomic, strong) BannerAd *adController;
@property(nonatomic, copy) NSString *lastLoadKey;
@property(nonatomic, copy) NSString *resourceSource;
@property(nonatomic, assign) NSTimeInterval requestStartedAt;
@end

@implementation BrayantBannerAdView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _visible = YES;
    _resourceSource = @"realtime";
    self.backgroundColor = UIColor.clearColor;
  }
  return self;
}

- (void)setRequestId:(NSString *)requestId {
  _requestId = [requestId copy];
  [self loadIfReady];
}

- (void)setCodeid:(NSString *)codeid {
  _codeid = [codeid copy];
  [self loadIfReady];
}

- (void)setPreloadToken:(NSString *)preloadToken {
  _preloadToken = [preloadToken copy];
  [self loadIfReady];
}

- (void)setAdWidth:(NSNumber *)adWidth {
  _adWidth = adWidth;
  [self loadIfReady];
}

- (void)setAdHeight:(NSNumber *)adHeight {
  _adHeight = adHeight;
  [self loadIfReady];
}

- (void)setVisible:(BOOL)visible {
  _visible = visible;
  self.hidden = !visible;
  if (visible) {
    [self loadIfReady];
  } else {
    [self.adController hide];
  }
}

- (void)loadIfReady {
  if (!self.visible || self.codeid.length == 0 ||
      self.adWidth.doubleValue <= 0 || self.adHeight.doubleValue <= 0) {
    return;
  }

  NSString *loadKey = [NSString
      stringWithFormat:@"%@:%@:%0.f:%0.f", self.requestId ?: @"", self.codeid,
                       self.adWidth.doubleValue, self.adHeight.doubleValue];
  if ([self.lastLoadKey isEqualToString:loadKey]) {
    return;
  }
  self.lastLoadKey = loadKey;
  self.requestStartedAt = [NSDate date].timeIntervalSince1970;
  self.resourceSource = @"realtime";
  [self emitState:@"loading" error:nil];

  AdResourceEntry *entry =
      [[AdResourceStore sharedStore] consumeToken:self.preloadToken
                                          format:@"banner"
                                          slotId:self.codeid
                                           width:self.adWidth.doubleValue
                                          height:self.adHeight.doubleValue];
  if (entry && [entry.resource isKindOfClass:[BannerAd class]]) {
    self.resourceSource = @"preloaded";
    self.adController = (BannerAd *)entry.resource;
    self.adController.delegate = self;
    [self emitState:@"loaded" error:nil];
    [self.adController showInView:self];
    return;
  }

  [self.adController removeAd];
  self.adController = [[BannerAd alloc] init];
  self.adController.delegate = self;
  __weak typeof(self) weakSelf = self;
  [self.adController loadAdWithSlotID:self.codeid
                             sizeType:BannerAdSizeTypeFixed
                                width:self.adWidth.doubleValue
                               height:self.adHeight.doubleValue
                           completion:^(BOOL success, NSError *error) {
                             __strong typeof(weakSelf) self = weakSelf;
                             if (!self) {
                               return;
                             }
                             if (!success) {
                               [self emitState:@"terminal" error:error];
                               return;
                             }
                             [self emitState:@"loaded" error:nil];
                             [self.adController showInView:self];
                           }];
}

- (void)bannerAdDidLoadSuccess:(BUNativeExpressBannerView *)ad {
  [self emitState:@"loaded" error:nil];
}

- (void)bannerAdDidLoadFail:(BUNativeExpressBannerView *)ad
                      error:(NSError *)error {
  [self emitState:@"terminal" error:error];
}

- (void)bannerAdDidShow:(BUNativeExpressBannerView *)ad {
  [self emitState:@"presented" error:nil];
}

- (void)bannerAdDidClick:(BUNativeExpressBannerView *)ad {
  [self emitState:@"presented" action:@"click" error:nil];
}

- (void)bannerAdDidDismiss:(BUNativeExpressBannerView *)ad {
  [self emitState:@"terminal" error:nil];
}

- (void)emitState:(NSString *)state error:(NSError *)error {
  [self emitState:state action:nil error:error];
}

- (void)emitState:(NSString *)state
           action:(NSString *)action
            error:(NSError *)error {
  if (!self.onAdEvent || self.requestId.length == 0) {
    return;
  }
  NSTimeInterval elapsed =
      self.requestStartedAt > 0
          ? ([NSDate date].timeIntervalSince1970 - self.requestStartedAt) * 1000
          : 0;
  NSMutableDictionary *payload = [@{
    @"requestId" : self.requestId,
    @"format" : @"banner",
    @"slotId" : self.codeid ?: @"",
    @"state" : state,
    @"source" : self.resourceSource ?: @"realtime",
    @"elapsedMs" : @(elapsed),
  } mutableCopy];
  if (action) {
    payload[@"action"] = action;
  }
  if ([state isEqualToString:@"presented"]) {
    payload[@"width"] = self.adWidth ?: @0;
    payload[@"height"] = self.adHeight ?: @0;
  }
  if (error) {
    payload[@"error"] = @{
      @"code" : @"BANNER_ERROR",
      @"message" : error.localizedDescription ?: @"广告加载失败",
      @"nativeCode" : @(error.code),
    };
  }
  self.onAdEvent(payload);
}

- (void)dealloc {
  self.adController.delegate = nil;
  [self.adController removeAd];
}

@end
