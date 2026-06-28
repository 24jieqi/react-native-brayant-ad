#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RewardedAdLoadCompletion)(BOOL success,
                                         NSError *_Nullable error);
typedef void (^RewardedAdEventHandler)(NSString *event,
                                       NSError *_Nullable error);
typedef void (^RewardedAdVerificationHandler)(BOOL valid,
                                              NSDictionary *reward,
                                              NSError *_Nullable error);
typedef void (^RewardedAdCompletion)(BOOL completed,
                                     NSError *_Nullable error);

@interface RewardedAd : NSObject

@property(nonatomic, copy, nullable) RewardedAdEventHandler eventHandler;
@property(nonatomic, copy, nullable)
    RewardedAdVerificationHandler verificationHandler;

- (void)loadAdWithSlotID:(NSString *)slotID
                  userId:(nullable NSString *)userId
              rewardName:(nullable NSString *)rewardName
            rewardAmount:(nullable NSNumber *)rewardAmount
                   extra:(nullable NSString *)extra
              completion:(RewardedAdLoadCompletion)completion;
- (void)showAdInRootViewController:(UIViewController *)rootViewController
                        completion:(RewardedAdCompletion)completion;
- (void)removeAd;

@end

NS_ASSUME_NONNULL_END
