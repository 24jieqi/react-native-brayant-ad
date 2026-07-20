//
//  ExpressNativeAd.m
//  Zhiya
//

#import "ExpressNativeAd.h"
#import "PangleAdModule.h"
#import <BUAdSDK/BUAdSlot.h>
#import <BUAdSDK/BUNativeExpressAdManager.h>
#import <BUAdSDK/BUNativeExpressAdView.h>

@interface ExpressNativeAd () <BUNativeExpressAdViewDelegate>

@property(nonatomic, strong) BUNativeExpressAdManager *expressAdManager;
@property(nonatomic, strong) BUNativeExpressAdView *expressAdView;
@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, assign) BOOL adLoaded;
@property(nonatomic, assign) BOOL adRendered;
@property(nonatomic, assign) BOOL renderRequested;
@property(nonatomic, copy) void (^loadCompletion)(BOOL, NSError *_Nullable);

@end

@implementation ExpressNativeAd

- (instancetype)init {
  self = [super init];
  if (self) {
    _adLoaded = NO;
    _adRendered = NO;
    _renderRequested = NO;
  }
  return self;
}

- (void)loadAdWithSlotID:(NSString *)slotID
                    width:(CGFloat)width
                   height:(CGFloat)height {
  [self loadAdWithSlotID:slotID width:width height:height completion:nil];
}

- (void)loadAdWithSlotID:(NSString *)slotID
                   width:(CGFloat)width
                  height:(CGFloat)height
              completion:(void (^)(BOOL, NSError *_Nullable))completion {
  if (!slotID || slotID.length == 0) {
    if (completion) {
      NSError *error =
          [NSError errorWithDomain:@"com.pangle.feed"
                              code:1000
                          userInfo:@{NSLocalizedDescriptionKey :
                                         @"SlotID 不能为空"}];
      completion(NO, error);
    }
    return;
  }

  self.adLoaded = NO;
  self.adRendered = NO;
  self.renderRequested = NO;
  self.expressAdView = nil;
  self.loadCompletion = completion;

  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
  CGFloat finalWidth = width > 0 ? width : screenWidth;

  CGSize adSize = CGSizeMake(finalWidth, height);

  BUAdSlot *slot = [[BUAdSlot alloc] init];
  slot.ID = slotID;
  slot.AdType = BUAdSlotAdTypeFeed;
  slot.imgSize = [BUSize sizeBy:BUProposalSize_Feed228_150];

  self.expressAdManager =
      [[BUNativeExpressAdManager alloc] initWithSlot:slot adSize:adSize];
  self.expressAdManager.delegate = self;

  [self.expressAdManager loadAdDataWithCount:1];
}

- (BOOL)isAdReady {
  return self.adLoaded && self.expressAdView != nil && self.adRendered;
}

- (void)registerContainerView:(UIView *)containerView
           rootViewController:(UIViewController *)rootViewController {
  if (!self.expressAdView || !containerView || !rootViewController) {
    return;
  }

  self.containerView = containerView;
  self.expressAdView.rootViewController = rootViewController;

  if (self.expressAdView.superview != containerView) {
    [self.expressAdView removeFromSuperview];
    self.expressAdView.frame = containerView.bounds;
    self.expressAdView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [containerView addSubview:self.expressAdView];
  }

  if (!self.renderRequested && !self.adRendered) {
    self.renderRequested = YES;
    [self.expressAdView render];
  }
}

#pragma mark - BUNativeExpressAdViewDelegate

- (void)nativeExpressAdSuccessToLoad:
            (BUNativeExpressAdManager *)nativeExpressAdManager
                               views:
                                   (NSArray<__kindof BUNativeExpressAdView *> *)
                                       views {
  if (views.count > 0) {
    self.expressAdView = views.firstObject;
    self.adLoaded = YES;

    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"PangleExpressNativeAdLoaded"
                      object:nil];

    if ([self.delegate respondsToSelector:@selector(expressAdDidLoad)]) {
      [self.delegate expressAdDidLoad];
    }
    if (self.loadCompletion) {
      self.loadCompletion(YES, nil);
      self.loadCompletion = nil;
    }
  } else {
    NSError *error =
        [NSError errorWithDomain:@"com.pangle.feed"
                            code:1001
                        userInfo:@{NSLocalizedDescriptionKey :
                                       @"广告素材列表为空"}];
    self.adLoaded = NO;
    self.adRendered = NO;
    if ([self.delegate
            respondsToSelector:@selector(expressAdDidFailWithError:)]) {
      [self.delegate expressAdDidFailWithError:error];
    }
    if (self.loadCompletion) {
      self.loadCompletion(NO, error);
      self.loadCompletion = nil;
    }
  }
}

- (void)nativeExpressAdFailToLoad:
            (BUNativeExpressAdManager *)nativeExpressAdManager
                            error:(NSError *)error {
  self.adLoaded = NO;
  self.adRendered = NO;

  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleExpressNativeAdLoadFail"
                    object:@{@"error" : error.localizedDescription}];

  if ([self.delegate
          respondsToSelector:@selector(expressAdDidFailWithError:)]) {
    [self.delegate expressAdDidFailWithError:error];
  }
  if (self.loadCompletion) {
    self.loadCompletion(NO, error);
    self.loadCompletion = nil;
  }
}

- (void)nativeExpressAdViewRenderSuccess:
    (BUNativeExpressAdView *)nativeExpressAdView {
  self.adRendered = YES;

  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleExpressNativeAdRenderSuccess"
                    object:nil];

  if ([self.delegate respondsToSelector:@selector(expressAdDidRender)]) {
    [self.delegate expressAdDidRender];
  }
}

- (void)nativeExpressAdViewRenderFail:
            (BUNativeExpressAdView *)nativeExpressAdView
                                error:(NSError *)error {
  self.adLoaded = NO;
  self.adRendered = NO;

  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleExpressNativeAdLoadFail"
                    object:@{@"error" : error.localizedDescription}];

  if ([self.delegate
          respondsToSelector:@selector(expressAdDidFailWithError:)]) {
    [self.delegate expressAdDidFailWithError:error];
  }
  if (self.loadCompletion) {
    self.loadCompletion(NO, error);
    self.loadCompletion = nil;
  }
}

- (void)nativeExpressAdViewWillShow:
    (BUNativeExpressAdView *)nativeExpressAdView {
  if (nativeExpressAdView != self.expressAdView) {
    return;
  }
  if ([self.delegate respondsToSelector:@selector(expressAdDidShow)]) {
    [self.delegate expressAdDidShow];
  }
}

- (void)nativeExpressAdViewDidClick:
    (BUNativeExpressAdView *)nativeExpressAdView {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleExpressNativeAdClicked"
                    object:nil];

  if ([self.delegate respondsToSelector:@selector(expressAdDidClick)]) {
    [self.delegate expressAdDidClick];
  }
}

- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView
      dislikeWithReason:(NSArray<BUDislikeWords *> *)filterwords {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"PangleExpressNativeAdClosed"
                    object:nil];

  [nativeExpressAdView removeFromSuperview];
  self.expressAdView = nil;
  self.adLoaded = NO;
  self.adRendered = NO;
  self.renderRequested = NO;

  if ([self.delegate respondsToSelector:@selector(expressAdDidClose)]) {
    [self.delegate expressAdDidClose];
  }
}

- (void)removeAd {
  [self.expressAdView removeFromSuperview];
  self.expressAdManager.delegate = nil;
  self.expressAdManager = nil;
  self.expressAdView = nil;
  self.containerView = nil;
  self.adLoaded = NO;
  self.adRendered = NO;
  self.renderRequested = NO;
  self.loadCompletion = nil;
}

@end
