//
//  InterstitialAd.h
//  Zhiya
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <BUAdSDK/BUNativeExpressFullscreenVideoAd.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^InterstitialCompletionBlock)(BOOL success, NSError * _Nullable error);
typedef void(^InterstitialLoadCompletionBlock)(BOOL success, NSError * _Nullable error);
typedef void(^InterstitialEventHandler)(NSString *event, NSError * _Nullable error);

@protocol InterstitialAdDelegate <NSObject>
@optional
- (void)interstitialAdDidLoadSuccess:(BUNativeExpressFullscreenVideoAd *)ad;
- (void)interstitialAdDidLoadFail:(BUNativeExpressFullscreenVideoAd *)ad error:(NSError *)error;
- (void)interstitialAdDidShow:(BUNativeExpressFullscreenVideoAd *)ad;
- (void)interstitialAdDidClick:(BUNativeExpressFullscreenVideoAd *)ad;
- (void)interstitialAdDidDismiss:(BUNativeExpressFullscreenVideoAd *)ad;
@end

@interface InterstitialAd : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, weak, nullable) id<InterstitialAdDelegate> delegate;
@property (nonatomic, strong, readonly, nullable) BUNativeExpressFullscreenVideoAd *interstitialAd;
@property(nonatomic, copy, nullable) InterstitialEventHandler eventHandler;

- (void)loadAdWithSlotID:(NSString *)slotID;
- (void)loadAdWithSlotID:(NSString *)slotID
              completion:(nullable InterstitialLoadCompletionBlock)completion;
- (BOOL)isAdReady;
- (void)showAdInRootViewController:(UIViewController *)rootVC
                          onComplete:(nullable InterstitialCompletionBlock)completeBlock;
- (void)removeAd;

@end

NS_ASSUME_NONNULL_END
