//
//  FeedAdViewManager.m
//  react-native-brayant-ad
//
//  Created by Sisyphus on 2024-01-18
//  Copyright © 2024 Pangle. All rights reserved.
//

#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/UIView+React.h>
#import "FeedAdView.h"

@interface FeedAdViewManager : RCTViewManager

@end

@implementation FeedAdViewManager

RCT_EXPORT_MODULE(FeedAdViewManager)

- (UIView *)view {
  return [[FeedAdView alloc] init];
}

#pragma mark - Properties

RCT_EXPORT_VIEW_PROPERTY(codeid, NSString)
RCT_EXPORT_VIEW_PROPERTY(requestId, NSString)
RCT_EXPORT_VIEW_PROPERTY(preloadToken, NSString)
RCT_EXPORT_VIEW_PROPERTY(adWidth, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(visible, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onAdError, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdLayout, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdClick, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdClose, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAdEvent, RCTBubblingEventBlock)

#pragma mark - Event Exports

- (NSArray<NSString *> *)customBubblingEventTypes {
  return @[
    @"onAdError",
    @"onAdLayout",
    @"onAdClick",
    @"onAdClose",
    @"onAdEvent"
  ];
}

@end
