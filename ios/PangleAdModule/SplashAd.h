//
//  SplashAd.h
//  Zhiya
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIViewController;

@interface SplashAd : NSObject

@property(nonatomic, copy, nullable)
    void (^eventHandler)(NSString *state, NSError *_Nullable error);

- (void)loadAdWithSlotID:(NSString *)slotID;
- (void)loadAdWithSlotID:(NSString *)slotID
              completion:(void (^)(BOOL success,
                                    NSError *_Nullable error))completion;

- (BOOL)isAdReady;

- (void)showAdInRootViewController:(UIViewController *)rootVC
                        onComplete:(void(^)(BOOL completed, NSError * _Nullable error))completeBlock;

- (void)removeAd;

@end

NS_ASSUME_NONNULL_END
