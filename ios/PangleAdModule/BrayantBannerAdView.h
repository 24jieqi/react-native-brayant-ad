#import <React/RCTComponent.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BrayantBannerAdView : UIView

@property(nonatomic, copy, nullable) NSString *requestId;
@property(nonatomic, copy, nullable) NSString *codeid;
@property(nonatomic, copy, nullable) NSString *preloadToken;
@property(nonatomic, strong, nullable) NSNumber *adWidth;
@property(nonatomic, strong, nullable) NSNumber *adHeight;
@property(nonatomic, assign) BOOL visible;
@property(nonatomic, copy, nullable) RCTBubblingEventBlock onAdEvent;

@end

NS_ASSUME_NONNULL_END
