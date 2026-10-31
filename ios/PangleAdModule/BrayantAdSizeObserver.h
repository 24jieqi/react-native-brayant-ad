#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/** 持续读取 SDK 视图的实际尺寸，不依赖第三方视图的 KVO 实现。 */
@interface BrayantAdSizeObserver : NSObject
- (instancetype)initWithView:(UIView *)view
               onSizeChange:(void (^)(CGSize size))onSizeChange;
- (void)start;
- (void)stop;
- (void)checkForSizeChange;
@end

NS_ASSUME_NONNULL_END
