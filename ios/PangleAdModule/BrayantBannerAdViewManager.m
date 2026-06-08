#import "BrayantBannerAdView.h"
#import <React/RCTViewManager.h>

@interface BrayantBannerAdViewManager : RCTViewManager
@end

@implementation BrayantBannerAdViewManager

RCT_EXPORT_MODULE(BrayantBannerAdView)

- (UIView *)view {
  return [[BrayantBannerAdView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(requestId, NSString)
RCT_EXPORT_VIEW_PROPERTY(codeid, NSString)
RCT_EXPORT_VIEW_PROPERTY(preloadToken, NSString)
RCT_EXPORT_VIEW_PROPERTY(adWidth, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(adHeight, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(visible, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onAdEvent, RCTBubblingEventBlock)

@end
