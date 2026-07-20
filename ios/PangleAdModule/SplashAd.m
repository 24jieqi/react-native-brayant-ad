//
//  SplashAd.m
//  Zhiya
//

#import "SplashAd.h"
#import "PangleAdModule.h"
#import <BUAdSDK/BUSplashAd.h>

@interface SplashAd () <BUSplashAdDelegate>

@property (nonatomic, strong) BUSplashAd *splashAd;
@property (nonatomic, copy) void(^completeBlock)(BOOL, NSError *);
@property (nonatomic, assign) BOOL adLoaded; // 广告已加载成功
@property(nonatomic, copy) void (^loadCompletion)(BOOL, NSError *_Nullable);
@property(nonatomic, assign) BOOL presentedFired;
@property(nonatomic, assign) BOOL terminalEventFired;
@property(nonatomic, assign) BOOL showCompletionFired;
@property(nonatomic, assign) BOOL presentationCancelled;
- (void)notifyPresentedIfNeeded;
- (void)notifyTerminalEventIfNeeded:(NSString *)state
                              error:(NSError *_Nullable)error;
- (void)completeShowIfNeeded:(BOOL)completed
                       error:(NSError *_Nullable)error;

@end

@implementation SplashAd

- (instancetype)init {
    self = [super init];
    if (self) {
        _adLoaded = NO;
        _presentedFired = NO;
        _terminalEventFired = NO;
        _showCompletionFired = NO;
        _presentationCancelled = NO;
    }
    return self;
}

- (void)loadAdWithSlotID:(NSString *)slotID {
    [self loadAdWithSlotID:slotID completion:nil];
}

- (void)loadAdWithSlotID:(NSString *)slotID
              completion:(void (^)(BOOL, NSError *_Nullable))completion {
    if (!slotID || slotID.length == 0) {
        NSLog(@"[Pangle] 开屏广告 SlotID 不能为空");
        if (completion) {
            NSError *error =
                [NSError errorWithDomain:@"com.pangle.splash"
                                     code:1000
                                 userInfo:@{NSLocalizedDescriptionKey:
                                                @"SlotID 不能为空"}];
            completion(NO, error);
        }
        return;
    }

    // 重置状态
    self.adLoaded = NO;
    self.splashAd = nil;
    self.loadCompletion = completion;
    self.completeBlock = nil;
    self.presentedFired = NO;
    self.terminalEventFired = NO;
    self.showCompletionFired = NO;
    self.presentationCancelled = NO;

    CGSize adSize = [UIScreen mainScreen].bounds.size;
    self.splashAd = [[BUSplashAd alloc] initWithSlotID:slotID adSize:adSize];
    self.splashAd.delegate = self;
    self.splashAd.tolerateTimeout = 5;
    self.splashAd.hideSkipButton = NO;

    NSLog(@"[Pangle] 开始加载开屏广告, SlotID: %@", slotID);
    [self.splashAd loadAdData];
}

- (BOOL)isAdReady {
    // 广告已加载且splashAd实例存在即为准备好
    return self.adLoaded && self.splashAd != nil;
}

- (void)showAdInRootViewController:(UIViewController *)rootVC
                          onComplete:(void(^)(BOOL completed, NSError *))completeBlock {
    self.completeBlock = completeBlock;

    if (!self.splashAd || !self.adLoaded) {
        NSError *error = [NSError errorWithDomain:@"com.pangle.splash"
                                             code:1001
                                          userInfo:@{NSLocalizedDescriptionKey: @"广告未加载"}];
        NSLog(@"[Pangle] 尝试展示广告但广告未加载");
        [self completeShowIfNeeded:NO error:error];
        return;
    }

    if (!rootVC) {
        NSError *error = [NSError errorWithDomain:@"com.pangle.splash"
                                             code:1002
                                          userInfo:@{NSLocalizedDescriptionKey: @"rootViewController 不能为空"}];
        NSLog(@"[Pangle] rootViewController 为空，无法展示广告");
        [self completeShowIfNeeded:NO error:error];
        return;
    }

    NSLog(@"[Pangle] 展示开屏广告");
    [self.splashAd showSplashViewInRootViewController:rootVC];
    // 展示后重置加载状态
    self.adLoaded = NO;
}

- (void)removeAd {
    self.presentationCancelled = YES;
    [self.splashAd removeSplashView];
    self.splashAd = nil;
    self.adLoaded = NO;
}

#pragma mark - BUSplashAdDelegate

- (void)splashAdLoadSuccess:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 开屏广告加载成功");
    self.adLoaded = YES;
}

- (void)splashAdLoadFail:(BUSplashAd *)splashAd error:(NSError *)error {
    NSLog(@"[Pangle] 开屏广告加载失败: %@", error.localizedDescription);
    self.adLoaded = NO;
    self.splashAd = nil;

    NSDictionary *payload = @{
        @"message": error.localizedDescription ?: @"广告加载失败",
        @"code": @(error.code)
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:PangleSplashAdLoadFail
                                                        object:payload];

    if (self.completeBlock) {
        [self completeShowIfNeeded:NO error:error];
    }
    if (self.loadCompletion) {
        self.loadCompletion(NO, error);
        self.loadCompletion = nil;
    }
}

- (void)splashAdRenderSuccess:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 开屏广告渲染成功");
    if (self.loadCompletion) {
        self.loadCompletion(YES, nil);
        self.loadCompletion = nil;
    }
}

- (void)splashAdRenderFail:(BUSplashAd *)splashAd error:(NSError *)error {
    NSLog(@"[Pangle] 开屏广告渲染失败: %@", error.localizedDescription);
    self.adLoaded = NO;
    if (self.loadCompletion) {
        self.loadCompletion(NO, error);
        self.loadCompletion = nil;
    }
    if (self.eventHandler) {
        [self notifyTerminalEventIfNeeded:@"failed" error:error];
    }
}

- (void)splashAdWillShow:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 开屏广告即将展示");
    // 聚合渠道不一定提供 didShow，延迟兜底，同时避免把 willShow 当成已上屏。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self notifyPresentedIfNeeded];
    });
}

- (void)splashAdDidShow:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 开屏广告已展示");
    [self notifyPresentedIfNeeded];
}

- (void)splashAdDidShowFailed:(BUSplashAd *)splashAd error:(NSError *)error {
    NSLog(@"[Pangle] 开屏广告展示失败: %@", error.localizedDescription);
    self.adLoaded = NO;
    [self notifyTerminalEventIfNeeded:@"failed" error:error];
    [self completeShowIfNeeded:NO error:error];
    [self removeAd];
}

- (void)splashAdDidClick:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 用户点击开屏广告");
}

- (void)splashAdDidClose:(BUSplashAd *)splashAd
               closeType:(BUSplashAdCloseType)closeType {
    NSLog(@"[Pangle] >>> splashAdDidClose called, closeType=%ld", (long)closeType);
    [self completeShowIfNeeded:YES error:nil];
    [self notifyTerminalEventIfNeeded:@"closed" error:nil];
    [self removeAd];

    // 启动页已在广告展示时隐藏，此处不再重复调用
    // 避免误判 React Native 根视图为启动页视图并隐藏它导致黑屏
}

- (void)splashAdDidCloseOther:(BUSplashAd *)splashAd closeType:(NSInteger)closeType {
    NSLog(@"[Pangle] 开屏广告其他方式关闭，类型: %ld", (long)closeType);
    [self completeShowIfNeeded:YES error:nil];
    [self notifyTerminalEventIfNeeded:@"closed" error:nil];
    [self removeAd];
}

- (void)splashAdCallback:(BUSplashAd *)splashAd withCallBackType:(NSInteger)callBackType {
    NSLog(@"[Pangle] 开屏广告回调类型: %ld", (long)callBackType);
}

#pragma mark - Event helpers

- (void)notifyPresentedIfNeeded {
    if (self.presentedFired || self.terminalEventFired ||
        self.presentationCancelled) {
        return;
    }
    self.presentedFired = YES;
    if (self.eventHandler) {
        self.eventHandler(@"presented", nil);
    }
}

- (void)notifyTerminalEventIfNeeded:(NSString *)state
                              error:(NSError *_Nullable)error {
    if (self.terminalEventFired) {
        return;
    }
    self.terminalEventFired = YES;
    if (self.eventHandler) {
        self.eventHandler(state, error);
    }
}

- (void)completeShowIfNeeded:(BOOL)completed
                       error:(NSError *_Nullable)error {
    if (self.showCompletionFired) {
        return;
    }
    self.showCompletionFired = YES;
    void (^completion)(BOOL, NSError *) = self.completeBlock;
    self.completeBlock = nil;
    if (completion) {
        completion(completed, error);
    }
}

@end
