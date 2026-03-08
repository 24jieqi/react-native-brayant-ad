//
//  SplashAd.m
//  Zhiya
//

#import "SplashAd.h"
#import <BUAdSDK/BUSplashAd.h>
#import "PangleAdModule.h"

@interface SplashAd () <BUSplashAdDelegate>

@property (nonatomic, strong) BUSplashAd *splashAd;
@property (nonatomic, copy) void(^completeBlock)(BOOL, NSError *);
@property (nonatomic, assign) BOOL adLoaded; // 广告已加载成功

@end

@implementation SplashAd

+ (instancetype)sharedInstance {
    static SplashAd *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SplashAd alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _adLoaded = NO;
    }
    return self;
}

- (void)loadAdWithSlotID:(NSString *)slotID {
    if (!slotID || slotID.length == 0) {
        NSLog(@"[Pangle] 开屏广告 SlotID 不能为空");
        return;
    }

    // 重置状态
    self.adLoaded = NO;
    self.splashAd = nil;

    CGSize adSize = [UIScreen mainScreen].bounds.size;
    self.splashAd = [[BUSplashAd alloc] initWithSlotID:slotID adSize:adSize];
    self.splashAd.delegate = self;
    self.splashAd.tolerateTimeout = 3;
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
        if (completeBlock) completeBlock(NO, error);
        return;
    }

    if (!rootVC) {
        NSError *error = [NSError errorWithDomain:@"com.pangle.splash"
                                             code:1002
                                          userInfo:@{NSLocalizedDescriptionKey: @"rootViewController 不能为空"}];
        NSLog(@"[Pangle] rootViewController 为空，无法展示广告");
        if (completeBlock) completeBlock(NO, error);
        return;
    }

    NSLog(@"[Pangle] 展示开屏广告");
    [self.splashAd showSplashViewInRootViewController:rootVC];
    // 展示后重置加载状态
    self.adLoaded = NO;
}

- (void)removeAd {
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
        self.completeBlock(NO, error);
    }
}

- (void)splashAdRenderSuccess:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 开屏广告渲染成功");
}

- (void)splashAdRenderFail:(BUSplashAd *)splashAd error:(NSError *)error {
    NSLog(@"[Pangle] 开屏广告渲染失败: %@", error.localizedDescription);
}

- (void)splashAdWillShow:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 开屏广告即将展示");
}

- (void)splashAdDidClick:(BUSplashAd *)splashAd {
    NSLog(@"[Pangle] 用户点击开屏广告");
}

- (void)splashAdDidClose:(BUSplashAd *)splashAd closeType:(NSInteger)closeType {
    NSLog(@"[Pangle] >>> splashAdDidClose called, closeType=%ld", (long)closeType);
    [self removeAd];

    // 启动页已在广告展示时隐藏，此处不再重复调用
    // 避免误判 React Native 根视图为启动页视图并隐藏它导致黑屏

    if (self.completeBlock) {
        self.completeBlock(YES, nil);
    }
    NSLog(@"[Pangle] >>> Calling notifyAdClosed");
    [[PangleAdModule sharedInstance] notifyAdClosed];
}

- (void)splashAdDidCloseOther:(BUSplashAd *)splashAd closeType:(NSInteger)closeType {
    NSLog(@"[Pangle] 开屏广告其他方式关闭，类型: %ld", (long)closeType);
    [self removeAd];

    // 启动页已在广告展示时隐藏，此处不再重复调用
    // 避免误判 React Native 根视图为启动页视图并隐藏它导致隐藏它导致黑屏

    if (self.completeBlock) {
        self.completeBlock(YES, nil);
    }
    // 通知 PangleAdModule 广告已关闭，由其转发给 React Native
    [[PangleAdModule sharedInstance] notifyAdClosed];
}

- (void)splashAdCallback:(BUSplashAd *)splashAd withCallBackType:(NSInteger)callBackType {
    NSLog(@"[Pangle] 开屏广告回调类型: %ld", (long)callBackType);
}

@end
