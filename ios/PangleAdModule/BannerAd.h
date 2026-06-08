//
//  BannerAd.h
//  Zhiya
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <BUAdSDK/BUNativeExpressBannerView.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BannerAdSizeType) {
    BannerAdSizeTypeStandard = 0,
    BannerAdSizeTypeMedium,
    BannerAdSizeTypeAdaptive,
    BannerAdSizeTypeFixed,
};

@protocol BannerAdDelegate <NSObject>
@optional
- (void)bannerAdDidLoadSuccess:(BUNativeExpressBannerView *)ad;
- (void)bannerAdDidLoadFail:(BUNativeExpressBannerView *)ad error:(NSError *)error;
- (void)bannerAdDidShow:(BUNativeExpressBannerView *)ad;
- (void)bannerAdDidClick:(BUNativeExpressBannerView *)ad;
- (void)bannerAdDidDismiss:(BUNativeExpressBannerView *)ad;
@end

@interface BannerAd : NSObject

@property (nonatomic, weak, nullable) id<BannerAdDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval refreshInterval;
@property (nonatomic, strong, readonly, nullable) BUNativeExpressBannerView *bannerAdView;
@property (nonatomic, strong, readonly, nullable) UIView *bannerView;

- (void)loadAdWithSlotID:(NSString *)slotID sizeType:(BannerAdSizeType)sizeType;
- (void)loadAdWithSlotID:(NSString *)slotID sizeType:(BannerAdSizeType)sizeType width:(double)width height:(double)height;
- (void)loadAdWithSlotID:(NSString *)slotID
                sizeType:(BannerAdSizeType)sizeType
                   width:(double)width
                  height:(double)height
              completion:(void (^)(BOOL success,
                                    NSError *_Nullable error))completion;
- (BOOL)isReadyForSlotID:(NSString *)slotID sizeType:(BannerAdSizeType)sizeType width:(double)width height:(double)height;
- (void)showInView:(UIView *)parentView;
- (void)hide;
- (void)removeAd;
- (void)startAutoRefresh;
- (void)stopAutoRefresh;

@end

NS_ASSUME_NONNULL_END
