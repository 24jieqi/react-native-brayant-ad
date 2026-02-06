//
//  FeedAdView.m
//  react-native-brayant-ad
//
//  Created by Sisyphus on 2024-01-18
//  Copyright © 2024 Pangle. All rights reserved.
//

#import "FeedAdView.h"
#import "ExpressNativeAd.h"
#import <React/RCTLog.h>

@interface FeedAdView () <ExpressNativeAdDelegate>

@property (nonatomic, strong) UIView *adContainerView;
@property (nonatomic, assign) BOOL isAdLoaded;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL didSendLayoutEvent;

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
  _didSendLayoutEvent = NO;
  
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
  
  RCTLog(@"[FeedAdView] 开始加载广告, codeid: %@, width: %.0f", _codeid, width);
  _didSendLayoutEvent = NO;
  
  // 设置 ExpressNativeAd 的 delegate
  [ExpressNativeAd sharedInstance].delegate = self;
  
  // 加载广告
  [[ExpressNativeAd sharedInstance] loadAdWithSlotID:_codeid width:width height:0];
}

#pragma mark - ExpressNativeAdDelegate

- (void)expressAdDidLoad {
  RCTLog(@"[FeedAdView] 广告加载成功");
  _isAdLoaded = YES;
  
  // 注册容器视图
  UIViewController *rootVC = [self getRootViewController];
  if (rootVC && [ExpressNativeAd sharedInstance].expressAdView) {
    [ExpressNativeAd sharedInstance].expressAdView.rootViewController = rootVC;
    [[ExpressNativeAd sharedInstance] registerContainerView:_adContainerView];
    
    // 触发渲染
    [[ExpressNativeAd sharedInstance].expressAdView render];
  }
}

- (void)expressAdDidFailWithError:(NSError *)error {
  RCTLogError(@"[FeedAdView] 广告加载失败: %@", error.localizedDescription);
  if (self.onAdError) {
    self.onAdError(@{@"error" : error.localizedDescription ?: @"广告加载失败"});
  }
}

- (void)expressAdDidClick {
  RCTLog(@"[FeedAdView] 广告被点击");
  if (self.onAdClick) {
    self.onAdClick(@{});
  }
}

- (void)expressAdDidClose {
  RCTLog(@"[FeedAdView] 广告关闭");
  if (self.onAdClose) {
    self.onAdClose(@{});
  }
}

- (void)expressAdDidShow {
  RCTLog(@"[FeedAdView] 广告展示");
  if (self.didSendLayoutEvent || !self.onAdLayout) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.didSendLayoutEvent || !self.onAdLayout) {
      return;
    }

    CGSize adSize = [ExpressNativeAd sharedInstance].expressAdView.bounds.size;
    CGFloat width = adSize.width > 0 ? adSize.width : self.adContainerView.bounds.size.width;
    CGFloat height = adSize.height > 0 ? adSize.height : self.adContainerView.bounds.size.height;

    if (height <= 0) {
      return;
    }

    self.didSendLayoutEvent = YES;
    self.onAdLayout(@{
      @"width" : @(width),
      @"height" : @(height),
    });
  });
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
