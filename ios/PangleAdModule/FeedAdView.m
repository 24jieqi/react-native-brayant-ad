//
//  FeedAdView.m
//  react-native-brayant-ad
//
//  Created by Sisyphus on 2024-01-18
//  Copyright © 2024 Pangle. All rights reserved.
//

#import "FeedAdView.h"
#import "AdResourceStore.h"
#import "ExpressNativeAd.h"
#import <React/RCTLog.h>

@interface FeedAdView () <ExpressNativeAdDelegate>

@property (nonatomic, strong) UIView *adContainerView;
@property (nonatomic, assign) BOOL isAdLoaded;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL didSendRenderedEvent;
@property (nonatomic, assign) BOOL didSendPresentedEvent;
@property (nonatomic, assign) BOOL pendingPresentation;
@property(nonatomic, strong) ExpressNativeAd *adController;
@property(nonatomic, copy) NSString *lastLoadKey;
@property(nonatomic, copy) NSString *resourceSource;
@property(nonatomic, assign) NSTimeInterval requestStartedAt;

@end

@implementation FeedAdView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupView];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupView];
  }
  return self;
}

- (void)setupView {
  _isAdLoaded = NO;
  _isVisible = YES;
  _didSendRenderedEvent = NO;
  _didSendPresentedEvent = NO;
  _pendingPresentation = NO;
  _adController = [[ExpressNativeAd alloc] init];
  _adController.delegate = self;
  _resourceSource = @"realtime";
  
  // 创建广告容器视图
  _adContainerView = [[UIView alloc] init];
  _adContainerView.backgroundColor = [UIColor clearColor];
  _adContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addSubview:_adContainerView];
  
  // 添加约束
  [NSLayoutConstraint activateConstraints:@[
    [_adContainerView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [_adContainerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [_adContainerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    [_adContainerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
  ]];
}

#pragma mark - Properties

- (void)setCodeid:(NSString *)codeid {
  _codeid = codeid;
  [self loadAdIfNeeded];
}

- (void)setAdWidth:(NSNumber *)adWidth {
  _adWidth = adWidth;
  [self loadAdIfNeeded];
}

- (void)setVisible:(BOOL)visible {
  _visible = visible;
  _isVisible = visible;
  self.hidden = !_isVisible;
}

- (void)setRequestId:(NSString *)requestId {
  _requestId = [requestId copy];
  [self loadAdIfNeeded];
}

- (void)setPreloadToken:(NSString *)preloadToken {
  _preloadToken = [preloadToken copy];
  [self loadAdIfNeeded];
}

#pragma mark - Ad Loading

- (void)loadAdIfNeeded {
  if (!_codeid || _codeid.length == 0) {
    RCTLogWarn(@"[FeedAdView] codeid 不能为空");
    return;
  }
  
  if (!_isVisible) {
    RCTLog(@"[FeedAdView] 广告不可见，跳过加载");
    return;
  }
  
  CGFloat width = [_adWidth doubleValue] > 0 ? [_adWidth doubleValue] : [UIScreen mainScreen].bounds.size.width;
  NSString *loadKey =
      [NSString stringWithFormat:@"%@:%@:%0.f", _requestId ?: @"", _codeid,
                                 width];
  if ([self.lastLoadKey isEqualToString:loadKey]) {
    return;
  }
  self.lastLoadKey = loadKey;
  self.requestStartedAt = [NSDate date].timeIntervalSince1970;
  self.resourceSource = @"realtime";
  [self emitEventWithState:@"loading" error:nil width:0 height:0];
  
  RCTLog(@"[FeedAdView] 开始加载广告, codeid: %@, width: %.0f", _codeid, width);
  _didSendRenderedEvent = NO;
  _didSendPresentedEvent = NO;
  _pendingPresentation = NO;

  AdResourceEntry *entry =
      [[AdResourceStore sharedStore] consumeToken:self.preloadToken
                                          format:@"feed"
                                          slotId:self.codeid
                                           width:width
                                          height:0];
  if (entry && [entry.resource isKindOfClass:[ExpressNativeAd class]]) {
    self.resourceSource = @"preloaded";
    self.adController.delegate = nil;
    [self.adController removeAd];
    self.adController = (ExpressNativeAd *)entry.resource;
    self.adController.delegate = self;
    [self emitEventWithState:@"loaded" error:nil width:0 height:0];
    [self attachCurrentAd];
    return;
  }

  self.adController.delegate = nil;
  [self.adController removeAd];
  self.adController = [[ExpressNativeAd alloc] init];
  self.adController.delegate = self;
  [self.adController loadAdWithSlotID:_codeid width:width height:0];
}

#pragma mark - ExpressNativeAdDelegate

- (void)expressAdDidLoad {
  RCTLog(@"[FeedAdView] 广告加载成功");
  _isAdLoaded = YES;
  [self emitEventWithState:@"loaded" error:nil width:0 height:0];
  [self attachCurrentAd];
}

- (void)attachCurrentAd {
  
  // 注册容器视图
  UIViewController *rootVC = [self getRootViewController];
  if (rootVC && self.adController.expressAdView) {
    self.adController.expressAdView.rootViewController = rootVC;
    [self.adController registerContainerView:_adContainerView];
    
    if ([self.adController isAdReady]) {
      [self expressAdDidRender];
    } else {
      [self emitEventWithState:@"rendering" error:nil width:0 height:0];
    }
  }
}

- (void)expressAdDidFailWithError:(NSError *)error {
  RCTLogError(@"[FeedAdView] 广告加载失败: %@", error.localizedDescription);
  if (self.onAdError) {
    self.onAdError(@{@"error" : error.localizedDescription ?: @"广告加载失败"});
  }
  [self emitEventWithState:@"terminal" error:error width:0 height:0];
}

- (void)expressAdDidClick {
  RCTLog(@"[FeedAdView] 广告被点击");
  if (self.onAdClick) {
    self.onAdClick(@{});
  }
  [self emitEventWithState:@"presented"
                    action:@"click"
                     error:nil
                     width:0
                    height:0];
}

- (void)expressAdDidClose {
  RCTLog(@"[FeedAdView] 广告关闭");
  if (self.onAdClose) {
    self.onAdClose(@{});
  }
  [self emitEventWithState:@"terminal" error:nil width:0 height:0];
}

- (void)expressAdDidRender {
  RCTLog(@"[FeedAdView] 广告渲染完成");
  if (self.didSendRenderedEvent) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.didSendRenderedEvent) {
      return;
    }

    CGSize adSize = self.adController.expressAdView.bounds.size;
    CGFloat width = adSize.width > 0 ? adSize.width : self.adContainerView.bounds.size.width;
    CGFloat height = adSize.height > 0 ? adSize.height : self.adContainerView.bounds.size.height;

    if (height <= 0) {
      return;
    }

    self.didSendRenderedEvent = YES;
    if (self.onAdLayout) {
      self.onAdLayout(@{
        @"width" : @(width),
        @"height" : @(height),
      });
    }
    [self emitEventWithState:@"rendered"
                       error:nil
                       width:width
                      height:height];
    if (self.pendingPresentation) {
      self.pendingPresentation = NO;
      [self expressAdDidShow];
    }
  });
}

- (void)expressAdDidShow {
  RCTLog(@"[FeedAdView] 广告开始展示");
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.didSendPresentedEvent) {
      return;
    }
    if (!self.didSendRenderedEvent) {
      self.pendingPresentation = YES;
      [self expressAdDidRender];
      return;
    }

    self.didSendPresentedEvent = YES;
    CGSize adSize = self.adController.expressAdView.bounds.size;
    [self emitEventWithState:@"presented"
                       error:nil
                       width:adSize.width
                      height:adSize.height];
  });
}

- (void)emitEventWithState:(NSString *)state
                     error:(NSError *)error
                     width:(CGFloat)width
                    height:(CGFloat)height {
  [self emitEventWithState:state
                    action:nil
                     error:error
                     width:width
                    height:height];
}

- (void)emitEventWithState:(NSString *)state
                    action:(NSString *)action
                     error:(NSError *)error
                     width:(CGFloat)width
                    height:(CGFloat)height {
  if (!self.onAdEvent || !self.requestId || self.requestId.length == 0) {
    return;
  }
  NSTimeInterval elapsed =
      self.requestStartedAt > 0
          ? ([NSDate date].timeIntervalSince1970 - self.requestStartedAt) * 1000
          : 0;
  NSMutableDictionary *payload = [@{
    @"requestId" : self.requestId,
    @"format" : @"feed",
    @"slotId" : self.codeid ?: @"",
    @"state" : state,
    @"source" : self.resourceSource ?: @"realtime",
    @"elapsedMs" : @(elapsed),
  } mutableCopy];
  if (action) {
    payload[@"action"] = action;
  }
  if (width > 0) {
    payload[@"width"] = @(width);
  }
  if (height > 0) {
    payload[@"height"] = @(height);
  }
  if (error) {
    payload[@"error"] = @{
      @"code" : @"FEED_ERROR",
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

#pragma mark - Helper

- (UIViewController *)getRootViewController {
  UIViewController *rootViewController = nil;
  
  // Try to get from connected scenes (iOS 13+)
  if (@available(iOS 13.0, *)) {
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
      if (scene.activationState == UISceneActivationStateForegroundActive) {
        for (UIWindow *window in scene.windows) {
          if (window.isKeyWindow) {
            rootViewController = window.rootViewController;
            break;
          }
        }
      }
      if (rootViewController)
        break;
    }
  }
  
  // Fallback to older method or if scene search failed
  if (!rootViewController) {
    rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
  }
  
  return rootViewController;
}

@end
