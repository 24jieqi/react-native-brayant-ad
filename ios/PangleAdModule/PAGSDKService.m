//
//  PAGSDKService.m
//  Zhiya
//

#import "PAGSDKService.h"
#import <BUAdSDK/BUAdSDKManager.h>
#import <BUAdSDK/BUAdSDKConfiguration.h>

@interface PAGSDKService ()

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, assign) BOOL isSDKInitialized;

@end

@implementation PAGSDKService

- (void)warnIfATSConfigurationMayBlockAdAssets {
    NSDictionary *ats =
        [NSBundle mainBundle].infoDictionary[@"NSAppTransportSecurity"];
    BOOL allowsArbitraryLoads = [ats[@"NSAllowsArbitraryLoads"] boolValue];
    BOOL hasFineGrainedGlobalKey =
        ats[@"NSAllowsArbitraryLoadsInWebContent"] != nil ||
        ats[@"NSAllowsArbitraryLoadsForMedia"] != nil ||
        ats[@"NSAllowsLocalNetworking"] != nil;
    if (!allowsArbitraryLoads || hasFineGrainedGlobalKey) {
        NSLog(@"[Pangle][ATS] 当前宿主配置无法放行广告 SDK 的原生 HTTP "
              @"图片请求。请设置 NSAllowsArbitraryLoads=YES，并移除 "
              @"NSAllowsArbitraryLoadsInWebContent、"
              @"NSAllowsArbitraryLoadsForMedia 和 NSAllowsLocalNetworking；"
              @"iOS 10 及以后只要存在这些细粒度键，就会忽略 "
              @"NSAllowsArbitraryLoads。详见 README。");
    }
}

+ (instancetype)sharedService {
    static PAGSDKService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PAGSDKService alloc] init];
    });
    return instance;
}

- (void)initializeSDKWithAppID:(NSString *)appID
                     completion:(PangleInitializationBlock)completion {
    if (self.isSDKInitialized) {
        if (completion) completion(YES, nil);
        return;
    }

    if (!appID || appID.length == 0) {
        NSError *error = [NSError errorWithDomain:@"com.pangle.sdk"
                                             code:1000
                                         userInfo:@{NSLocalizedDescriptionKey: @"AppID 不能为空"}];
        if (completion) completion(NO, error);
        return;
    }

    self.appID = appID;
    [self warnIfATSConfigurationMayBlockAdAssets];

    // 注册 AppID，并补齐调试日志级别。
    BUAdSDKConfiguration *config = [BUAdSDKConfiguration configuration];
    config.appID = appID;
#ifdef DEBUG
    config.debugLog = @(YES);
    config.SDKDEBUG = YES;
#else
    config.debugLog = @(NO);
    config.SDKDEBUG = NO;
#endif
    NSLog(@"[Pangle] 开始初始化 SDK, AppID: %@", appID);

    [BUAdSDKManager startWithAsyncCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        self.isSDKInitialized = success;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSLog(@"[Pangle] SDK 初始化成功, AppID: %@, Version: %@", appID, [BUAdSDKManager SDKVersion]);
            } else {
                NSLog(@"[Pangle] SDK 初始化失败: %@", error.localizedDescription);
            }

            if (completion) {
                completion(success, error);
            }
        });
    }];
}

- (BOOL)isInitialized {
    return [BUAdSDKManager state] == BUAdSDKStateStart;
}

- (NSString *)SDKVersion {
    return [BUAdSDKManager SDKVersion];
}

@end
