//
//  ExpressNativeAd.h
//  Zhiya
//

#import <BUAdSDK/BUNativeExpressAdManager.h>
#import <BUAdSDK/BUNativeExpressAdView.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ExpressNativeAdDelegate <NSObject>
@optional
- (void)expressAdDidLoad;
- (void)expressAdDidFailWithError:(NSError *)error;
- (void)expressAdDidRender;
- (void)expressAdDidShow;
- (void)expressAdDidClick;
- (void)expressAdDidClose;
@end

@interface ExpressNativeAd : NSObject

@property(nonatomic, weak, nullable) id<ExpressNativeAdDelegate> delegate;
@property(nonatomic, strong, readonly, nullable)
    BUNativeExpressAdView *expressAdView;

- (void)loadAdWithSlotID:(NSString *)slotID
                   width:(CGFloat)width
                  height:(CGFloat)height;
- (void)loadAdWithSlotID:(NSString *)slotID
                   width:(CGFloat)width
                  height:(CGFloat)height
              completion:(void (^)(BOOL success,
                                    NSError *_Nullable error))completion;
- (BOOL)isAdReady;
- (void)registerContainerView:(UIView *)containerView
           rootViewController:(UIViewController *)rootViewController;
- (void)removeAd;

@end

NS_ASSUME_NONNULL_END
