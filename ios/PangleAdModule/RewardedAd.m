#import "RewardedAd.h"
#import <BUAdSDK/BUNativeExpressRewardedVideoAd.h>
#import <BUAdSDK/BURewardedVideoModel.h>

@interface RewardedAd () <BUNativeExpressRewardedVideoAdDelegate>

@property(nonatomic, strong)
    BUNativeExpressRewardedVideoAd *rewardedVideoAd;
@property(nonatomic, copy) RewardedAdLoadCompletion loadCompletion;
@property(nonatomic, copy) RewardedAdCompletion completion;
@property(nonatomic, assign) BOOL ready;

@end

@implementation RewardedAd

- (void)loadAdWithSlotID:(NSString *)slotID
                  userId:(NSString *)userId
              rewardName:(NSString *)rewardName
            rewardAmount:(NSNumber *)rewardAmount
                   extra:(NSString *)extra
              completion:(RewardedAdLoadCompletion)completion {
  if (slotID.length == 0) {
    NSError *error = [NSError errorWithDomain:@"com.brayant.rewarded"
                                         code:1001
                                     userInfo:@{
                                       NSLocalizedDescriptionKey :
                                           @"激励视频广告位不能为空"
                                     }];
    completion(NO, error);
    return;
  }

  [self removeAd];
  self.loadCompletion = completion;
  BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
  model.userId = userId ?: @"";
  model.rewardName = rewardName;
  model.rewardAmount = rewardAmount.integerValue;
  model.extra = extra;
  self.rewardedVideoAd = [[BUNativeExpressRewardedVideoAd alloc]
      initWithSlotID:slotID
      rewardedVideoModel:model];
  self.rewardedVideoAd.delegate = self;
  [self.rewardedVideoAd loadAdData];
}

- (void)showAdInRootViewController:(UIViewController *)rootViewController
                        completion:(RewardedAdCompletion)completion {
  self.completion = completion;
  if (!self.rewardedVideoAd || !self.ready || !rootViewController) {
    NSError *error = [NSError errorWithDomain:@"com.brayant.rewarded"
                                         code:1002
                                     userInfo:@{
                                       NSLocalizedDescriptionKey :
                                           @"激励视频尚未准备完成"
                                     }];
    completion(NO, error);
    return;
  }
  BOOL shown =
      [self.rewardedVideoAd showAdFromRootViewController:rootViewController];
  if (!shown) {
    NSError *error = [NSError errorWithDomain:@"com.brayant.rewarded"
                                         code:1003
                                     userInfo:@{
                                       NSLocalizedDescriptionKey :
                                           @"激励视频展示失败"
                                     }];
    completion(NO, error);
  }
  self.ready = NO;
}

- (void)removeAd {
  self.rewardedVideoAd.delegate = nil;
  self.rewardedVideoAd = nil;
  self.ready = NO;
  self.loadCompletion = nil;
  self.completion = nil;
  self.eventHandler = nil;
  self.verificationHandler = nil;
}

- (void)finishLoad:(BOOL)success error:(NSError *)error {
  RewardedAdLoadCompletion completion = self.loadCompletion;
  self.loadCompletion = nil;
  if (completion) completion(success, error);
}

- (NSDictionary *)rewardPayloadWithValid:(BOOL)valid {
  BURewardedVideoModel *model = self.rewardedVideoAd.rewardedVideoModel;
  return @{
    @"valid" : @(valid),
    @"type" : @0,
    @"name" : model.rewardName ?: @"",
    @"amount" : @(model.rewardAmount),
    @"proposedAmount" : @1,
  };
}

#pragma mark - BUNativeExpressRewardedVideoAdDelegate

- (void)nativeExpressRewardedVideoAdDidLoad:
    (BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
}

- (void)nativeExpressRewardedVideoAdDidDownLoadVideo:
    (BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
  self.ready = YES;
  [self finishLoad:YES error:nil];
}

- (void)nativeExpressRewardedVideoAd:
            (BUNativeExpressRewardedVideoAd *)rewardedVideoAd
                    didFailWithError:(NSError *)error {
  self.ready = NO;
  [self finishLoad:NO error:error];
  if (self.eventHandler) self.eventHandler(@"failed", error);
}

- (void)nativeExpressRewardedVideoAdDidShowFailed:
            (BUNativeExpressRewardedVideoAd *)rewardedVideoAd
                                           error:(NSError *)error {
  if (self.eventHandler) self.eventHandler(@"failed", error);
  if (self.completion) self.completion(NO, error);
}

- (void)nativeExpressRewardedVideoAdDidVisible:
    (BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
  if (self.eventHandler) self.eventHandler(@"presented", nil);
}

- (void)nativeExpressRewardedVideoAdDidClick:
    (BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
  if (self.eventHandler) self.eventHandler(@"click", nil);
}

- (void)nativeExpressRewardedVideoAdDidClickSkip:
    (BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
  if (self.eventHandler) self.eventHandler(@"skip", nil);
}

- (void)nativeExpressRewardedVideoAdDidPlayFinish:
            (BUNativeExpressRewardedVideoAd *)rewardedVideoAd
                                  didFailWithError:(NSError *)error {
  if (self.eventHandler)
    self.eventHandler(error ? @"playback-failed" : @"video-complete", error);
}

- (void)nativeExpressRewardedVideoAdServerRewardDidSucceed:
            (BUNativeExpressRewardedVideoAd *)rewardedVideoAd
                                                  verify:(BOOL)verify {
  if (self.verificationHandler) {
    self.verificationHandler(verify,
                             [self rewardPayloadWithValid:verify], nil);
  }
}

- (void)nativeExpressRewardedVideoAdServerRewardDidFail:
            (BUNativeExpressRewardedVideoAd *)rewardedVideoAd
                                                   error:(NSError *)error {
  if (self.verificationHandler) {
    self.verificationHandler(NO, [self rewardPayloadWithValid:NO], error);
  }
}

- (void)nativeExpressRewardedVideoAdDidClose:
    (BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
  if (self.eventHandler) self.eventHandler(@"closed", nil);
  RewardedAdCompletion completion = self.completion;
  self.completion = nil;
  if (completion) completion(YES, nil);
  [self removeAd];
}

@end
