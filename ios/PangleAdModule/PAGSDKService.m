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
    BOOL allowsWebContent =
        [ats[@"NSAllowsArbitraryLoadsInWebContent"] boolValue];
    BOOL allowsMedia = [ats[@"NSAllowsArbitraryLoadsForMedia"] boolValue];
    if (!allowsWebContent || !allowsMedia) {
        NSLog(@"[Pangle][ATS] 宿主 Info.plist 缺少 "
              @"NSAllowsArbitraryLoadsInWebContent 或 "
              @"NSAllowsArbitraryLoadsForMedia；HTTP 广告图片/视频可能被 "
              @"ATS 拦截并显示为空白。请按 README 配置定向例外。");
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
