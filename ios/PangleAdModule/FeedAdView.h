//
//  FeedAdView.h
//  react-native-brayant-ad
//
//  Created by Sisyphus on 2024-01-18
//  Copyright © 2024 Pangle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeedAdView : UIView

@property (nonatomic, copy, nullable) NSString *codeid;
@property (nonatomic, strong, nullable) NSNumber *adWidth;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, copy, nullable) RCTBubblingEventBlock onAdError;
@property (nonatomic, copy, nullable) RCTBubblingEventBlock onAdLayout;
@property (nonatomic, copy, nullable) RCTBubblingEventBlock onAdClick;
@property (nonatomic, copy, nullable) RCTBubblingEventBlock onAdClose;

@end

NS_ASSUME_NONNULL_END
