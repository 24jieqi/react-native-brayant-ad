//
//  BannerAd.m
//  Zhiya
//

#import "BannerAd.h"
#import "PangleAdModule.h"
#import <BUAdSDK/BUAdSDKManager.h>
#import <BUAdSDK/BUAdSlot.h>
#import <BUAdSDK/BUNativeExpressBannerView.h>
#import <BUAdSDK/BUSize.h>
#import <math.h>

@interface BannerAd () <BUNativeExpressBannerViewDelegate>

@property(nonatomic, strong) BUNativeExpressBannerView *bannerAdView;
@property(nonatomic, strong) UIView *bannerView;
@property(nonatomic, strong) NSTimer *refreshTimer;
@property(nonatomic, assign) BOOL adLoaded;
@property(nonatomic, assign) BOOL adRendered;
@property(nonatomic, copy) NSString *currentSlotID;
@property(nonatomic, assign) BannerAdSizeType currentSizeType;
@property(nonatomic, assign) double fixedWidth;
@property(nonatomic, assign) double fixedHeight;
@property(nonatomic, weak) UIView *currentParentView;

@end

@implementation BannerAd

+ (instancetype)sharedInstance {
  static BannerAd *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[BannerAd alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _refreshInterval = 0;
    _adLoaded = NO;
    _adRendered = NO;
  }
  return self;
}

- (void)dealloc {
  [self stopAutoRefresh];
}

- (void)loadAdWithSlotID:(NSString *)slotID
                 sizeType:(BannerAdSizeType)sizeType {
  [self loadAdWithSlotID:slotID sizeType:sizeType width:0 height:0];
}

- (void)loadAdWithSlotID:(NSString *)slotID
                 sizeType:(BannerAdSizeType)sizeType
                    width:(double)width
                    height:(double)height {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!slotID || slotID.length == 0) {
      NSLog(@"[Pangle] Banner广告 SlotID 不能为空");
      return;
    }

    BOOL sameSlot =
        self.currentSlotID != nil && [self.currentSlotID isEqualToString:slotID];
    BOOL sameConfig = sameSlot && self.currentSizeType == sizeType &&
                      fabs(self.fixedWidth - width) < 0.1 &&
                      fabs(self.fixedHeight - height) < 0.1;
    if (sameConfig && self.bannerAdView != nil && self.adLoaded) {
      [[NSNotificationCenter defaultCenter]
          postNotificationName:@"PangleBannerAdLoaded"
                        object:nil];

      if (self.adRendered) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"PangleBannerAdRenderSuccess"
                          object:nil];
      }
      return;
    }

    [self stopAutoRefresh];
    [self.bannerView removeFromSuperview];
    self.bannerView = nil;
    self.adLoaded = NO;
    self.adRendered = NO;
    self.bannerAdView.delegate = nil;
    self.bannerAdView = nil;
    self.currentSlotID = slotID;
    self.currentSizeType = sizeType;
    self.fixedWidth = width;
    self.fixedHeight = height;

    CGSize cgSize = [self sizeForType:sizeType width:width height:height];

    BUSize *size = [[BUSize alloc] init];
    size.width = (NSInteger)cgSize.width;
    size.height = (NSInteger)cgSize.height;

    BUAdSlot *slot = [[BUAdSlot alloc] init];
    slot.ID = slotID;
    slot.position = BUAdSlotPositionBottom;
    slot.imgSize = size;

    NSLog(@"[Pangle] 开始加载Banner广告, SlotID: %@, Size: %@", slotID,
          NSStringFromCGSize(cgSize));

    UIViewController *rootVC = [self topViewController];
    if (!rootVC) {
      NSError *error = [NSError
          errorWithDomain:@"com.pangle.banner"
                     code:1001
                 userInfo:@{NSLocalizedDescriptionKey : @"无法获取根视图控制器"}];
      NSLog(@"[Pangle] 错误：无法获取根视图控制器");
      [[NSNotificationCenter defaultCenter]
          postNotificationName:@"PangleBannerAdLoadFail"
                        object:@{@"error" : error.localizedDescription}];
      self.adLoaded = NO;
      return;
    }
    NSLog(@"[Pangle] 根视图控制器: %@", rootVC);

    BUNativeExpressBannerView *bannerView =
        [[BUNativeExpressBannerView alloc] initWithSlot:slot
                                     rootViewController:rootVC
                                                 adSize:cgSize];
    bannerView.delegate = self;
    self.bannerAdView = bannerView;

    NSLog(@"[Pangle] BannerAd 创建完成，准备调用 loadAdData");
    [bannerView loadAdData];
    NSLog(@"[Pangle] BannerAd loadAdData 已调用");
  });
}

- (UIViewController *)topViewController {
  UIViewController *rootViewController = nil;

  // Try to get from connected scenes (iOS 13+)
  if (@available(iOS 13.0, *)) {
    for (UIWindowScene *scene in [UIApplication sharedApplication]
             .connectedScenes) {
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
    rootViewController =
        [UIApplication sharedApplication].keyWindow.rootViewController;
  }

  if (!rootViewController) {
    // Last resort: application delegate window
    rootViewController =
        [UIApplication sharedApplication].delegate.window.rootViewController;
  }

  if (!rootViewController) {
    NSLog(@"[Pangle] window.rootViewController 为空");
    return nil;
  }
  NSLog(@"[Pangle] rootViewController: %@, view frame: %@", rootViewController,
        NSStringFromCGRect(rootViewController.view.frame));

  while (rootViewController.presentedViewController) {
    // Avoid using presentedViewController if it is being dismissed
    if (rootViewController.presentedViewController.isBeingDismissed) {
      break;
    }
    rootViewController = rootViewController.presentedViewController;
  }
  return rootViewController;
}

- (CGSize)sizeForType:(BannerAdSizeType)sizeType width:(double)width height:(double)height {
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
  switch (sizeType) {
  case BannerAdSizeTypeFixed:
    return CGSizeMake(width, height);
  case BannerAdSizeTypeStandard:
    return CGSizeMake(screenWidth, 50);
  case BannerAdSizeTypeMedium:
    return CGSizeMake(300, 250);
  case BannerAdSizeTypeAdaptive:
  default:
    return CGSizeMake(screenWidth, 60);
  }
}

- (CGSize)sizeForType:(BannerAdSizeType)sizeType {
  return [self sizeForType:sizeType width:0 height:0];
}

- (BOOL)isReadyForSlotID:(NSString *)slotID
                sizeType:(BannerAdSizeType)sizeType
                   width:(double)width
                  height:(double)height {
  BOOL sameSlot =
      self.currentSlotID != nil && [self.currentSlotID isEqualToString:slotID];
  BOOL sameConfig = sameSlot && self.currentSizeType == sizeType &&
                    fabs(self.fixedWidth - width) < 0.1 &&
                    fabs(self.fixedHeight - height) < 0.1;

  return sameConfig && self.bannerAdView != nil && self.adLoaded &&
         self.adRendered;
}

- (void)attachBannerView:(BUNativeExpressBannerView *)bannerView
            toParentView:(UIView *)parentView {
  if (!bannerView || !parentView) {
    return;
  }

  if (self.bannerView == bannerView && bannerView.superview == parentView) {
    [parentView bringSubviewToFront:bannerView];
    return;
  }

  [self.bannerView removeFromSuperview];
  self.bannerView = bannerView;

  CGSize size = [self sizeForType:self.currentSizeType
                            width:self.fixedWidth
                           height:self.fixedHeight];
  self.bannerView.frame = CGRectMake(0, 0, size.width, size.height);
  self.bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  if (bannerView.superview != parentView) {
    [bannerView removeFromSuperview];
    [parentView addSubview:bannerView];
  }

  [parentView bringSubviewToFront:bannerView];

  if ([self.delegate respondsToSelector:@selector(bannerAdDidShow:)]) {
    [self.delegate bannerAdDidShow:bannerView];
  }
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleBannerAdShowed"
                    object:nil];

  if (self.refreshInterval > 0 && self.refreshTimer == nil) {
    [self startAutoRefresh];
  }
}

- (void)showInView:(UIView *)parentView {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!parentView) {
      NSLog(@"[Pangle] parentView 不能为空");
      return;
    }

    self.currentParentView = parentView;

    if (!self.bannerAdView || !self.adLoaded) {
      NSLog(@"[Pangle] Banner广告暂未就绪，加载完成后自动展示");
      return;
    }

    [self attachBannerView:self.bannerAdView toParentView:parentView];
  });
}

- (void)hide {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self stopAutoRefresh];
    [self.bannerView removeFromSuperview];
    self.bannerView = nil;
    self.currentParentView = nil;
    self.adRendered = NO;
    NSLog(@"[Pangle] Banner广告已隐藏");
  });
}

- (void)removeAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self stopAutoRefresh];
    [self.bannerView removeFromSuperview];
    self.bannerView = nil;
    self.bannerAdView.delegate = nil;
    self.bannerAdView = nil;
    self.currentParentView = nil;
    self.adLoaded = NO;
    self.adRendered = NO;
    NSLog(@"[Pangle] Banner广告已移除");
  });
}

- (void)startAutoRefresh {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self stopAutoRefresh];
    if (self.refreshInterval <= 0) {
      return;
    }

    NSLog(@"[Pangle] Banner广告开始自动刷新, 间隔: %.0f秒", self.refreshInterval);
    self.refreshTimer =
        [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                         target:self
                                       selector:@selector(refreshAd)
                                       userInfo:nil
                                        repeats:YES];
  });
}

- (void)stopAutoRefresh {
  [self.refreshTimer invalidate];
  self.refreshTimer = nil;
}

- (void)refreshAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.currentSlotID && self.currentSlotID.length > 0) {
      NSLog(@"[Pangle] Banner广告自动刷新");
      [self loadAdWithSlotID:self.currentSlotID
                     sizeType:self.currentSizeType
                        width:self.fixedWidth
                       height:self.fixedHeight];
    }
  });
}

#pragma mark - BUNativeExpressBannerViewDelegate

- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {
    NSLog(@"[Pangle] Banner广告加载成功");
    self.adLoaded = YES;
    self.adRendered = NO;
    UIView *parentView = self.currentParentView;
    if (parentView) {
        [self attachBannerView:bannerAdView toParentView:parentView];
    }
    if ([self.delegate respondsToSelector:@selector(bannerAdDidLoadSuccess:)]) {
        [self.delegate bannerAdDidLoadSuccess:bannerAdView];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PangleBannerAdLoaded" object:nil];
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView didLoadFailWithError:(NSError *)error {
    NSLog(@"[Pangle] Banner广告加载失败: %@", error.localizedDescription);
    self.adLoaded = NO;
    if ([self.delegate respondsToSelector:@selector(bannerAdDidLoadFail:error:)]) {
        [self.delegate bannerAdDidLoadFail:bannerAdView error:error];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PangleBannerAdLoadFail" object:@{@"error": error.localizedDescription}];
}

- (void)nativeExpressBannerAdViewRenderSuccess:
    (BUNativeExpressBannerView *)bannerAdView {
  NSLog(@"[Pangle] Banner广告渲染成功");
  self.adRendered = YES;
  // 发送渲染成功事件给 React Native
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleBannerAdRenderSuccess"
                    object:nil];
}

- (void)nativeExpressBannerAdViewRenderFail:
            (BUNativeExpressBannerView *)bannerAdView
                                      error:(NSError *)error {
  NSLog(@"[Pangle] Banner广告渲染失败: %@", error.localizedDescription);
  self.adRendered = NO;
}

- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
    NSLog(@"[Pangle] 用户点击Banner广告");
    if ([self.delegate respondsToSelector:@selector(bannerAdDidClick:)]) {
        [self.delegate bannerAdDidClick:bannerAdView];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PangleBannerAdClicked" object:nil];
}

- (void)nativeExpressBannerAdViewDidDismiss:
    (BUNativeExpressBannerView *)bannerAdView {
  NSLog(@"[Pangle] Banner广告关闭");
  self.adLoaded = NO;
  self.adRendered = NO;

  [self removeAd];

  if ([self.delegate respondsToSelector:@selector(bannerAdDidDismiss:)]) {
    [self.delegate bannerAdDidDismiss:bannerAdView];
  }
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleBannerAdClosed"
                    object:nil];

  if (self.refreshInterval > 0) {
    [self startAutoRefresh];
  }
}

@end
