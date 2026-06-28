package com.brayantad.core;

import android.app.Activity;
import android.os.Bundle;

import com.brayantad.utils.RewardBundleModel;
import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.TTAdLoadType;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTRewardVideoAd;

import java.util.concurrent.atomic.AtomicBoolean;

public final class RewardedAdController {
  private RewardedAdController() {}

  public interface LoadCallback {
    void onLoaded(TTRewardVideoAd ad);
    void onError(int code, String message);
  }

  public interface InteractionCallback {
    void onPresented();
    void onClick();
    void onClosed();
    void onVideoComplete();
    void onVideoError();
    void onReward(RewardData reward);
    void onSkipped();
  }

  public static final class RewardData {
    public final boolean valid;
    public final int type;
    public final String name;
    public final int amount;
    public final float proposedAmount;
    public final int errorCode;
    public final String errorMessage;

    RewardData(boolean valid, int type, Bundle bundle) {
      RewardBundleModel model = new RewardBundleModel(bundle != null ? bundle : new Bundle());
      this.valid = valid;
      this.type = type;
      this.name = model.getRewardName();
      this.amount = model.getRewardAmount();
      this.proposedAmount = model.getRewardPropose();
      this.errorCode = model.getServerErrorCode();
      this.errorMessage = model.getServerErrorMsg();
    }
  }

  public static void load(
    TTAdNative adNative,
    String slotId,
    String userId,
    String rewardName,
    Integer rewardAmount,
    String extra,
    boolean preload,
    LoadCallback callback
  ) {
    AdSlot.Builder builder = new AdSlot.Builder()
      .setCodeId(slotId)
      .setExpressViewAcceptedSize(500, 500)
      .setAdLoadType(preload ? TTAdLoadType.PRELOAD : TTAdLoadType.LOAD);
    if (userId != null && !userId.isEmpty()) {
      builder.setUserID(userId);
    }
    if (rewardName != null && !rewardName.isEmpty()) {
      builder.setRewardName(rewardName);
    }
    if (rewardAmount != null && rewardAmount > 0) {
      builder.setRewardAmount(rewardAmount);
    }
    if (extra != null && !extra.isEmpty()) {
      builder.setMediaExtra(extra);
    }

    AtomicBoolean delivered = new AtomicBoolean(false);
    adNative.loadRewardVideoAd(
      builder.build(),
      new TTAdNative.RewardVideoAdListener() {
        @Override
        public void onError(int code, String message) {
          if (delivered.compareAndSet(false, true)) {
            callback.onError(code, message);
          }
        }

        @Override
        public void onRewardVideoAdLoad(TTRewardVideoAd ad) {}

        @Override
        public void onRewardVideoCached() {}

        @Override
        public void onRewardVideoCached(TTRewardVideoAd ad) {
          if (delivered.compareAndSet(false, true)) {
            callback.onLoaded(ad);
          }
        }
      }
    );
  }

  public static void show(
    Activity activity,
    TTRewardVideoAd ad,
    InteractionCallback callback
  ) {
    ad.setRewardAdInteractionListener(
      new TTRewardVideoAd.RewardAdInteractionListener() {
        @Override
        public void onAdShow() {
          callback.onPresented();
        }

        @Override
        public void onAdVideoBarClick() {
          callback.onClick();
        }

        @Override
        public void onAdClose() {
          callback.onClosed();
        }

        @Override
        public void onVideoComplete() {
          callback.onVideoComplete();
        }

        @Override
        public void onVideoError() {
          callback.onVideoError();
        }

        @Override
        public void onRewardVerify(
          boolean rewardVerify,
          int rewardAmount,
          String rewardName,
          int errorCode,
          String errorMessage
        ) {}

        @Override
        public void onRewardArrived(
          boolean isRewardValid,
          int rewardType,
          Bundle extraInfo
        ) {
          callback.onReward(new RewardData(isRewardValid, rewardType, extraInfo));
        }

        @Override
        public void onSkippedVideo() {
          callback.onSkipped();
        }
      }
    );
    ad.showRewardVideoAd(activity);
  }
}
