package com.brayantad.core;

import android.app.Activity;

import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.TTAdLoadType;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTFullScreenVideoAd;

import java.util.concurrent.atomic.AtomicBoolean;

public final class InterstitialAdController {
  private InterstitialAdController() {}

  public interface LoadCallback {
    void onLoaded(TTFullScreenVideoAd ad);
    void onError(int code, String message);
  }

  public interface InteractionCallback {
    void onPresented();
    void onClick();
    void onClosed();
    void onVideoComplete();
    void onSkipped();
  }

  public static void load(
    TTAdNative adNative,
    String slotId,
    boolean preload,
    LoadCallback callback
  ) {
    AdSlot adSlot = new AdSlot.Builder()
      .setCodeId(slotId)
      .setExpressViewAcceptedSize(500, 500)
      .setSupportDeepLink(true)
      .setAdLoadType(preload ? TTAdLoadType.PRELOAD : TTAdLoadType.LOAD)
      .build();
    AtomicBoolean delivered = new AtomicBoolean(false);
    adNative.loadFullScreenVideoAd(
      adSlot,
      new TTAdNative.FullScreenVideoAdListener() {
        @Override
        public void onError(int code, String message) {
          if (delivered.compareAndSet(false, true)) {
            callback.onError(code, message);
          }
        }

        @Override
        public void onFullScreenVideoAdLoad(TTFullScreenVideoAd ad) {}

        @Override
        public void onFullScreenVideoCached() {}

        @Override
        public void onFullScreenVideoCached(TTFullScreenVideoAd ad) {
          if (delivered.compareAndSet(false, true)) {
            callback.onLoaded(ad);
          }
        }
      }
    );
  }

  public static void show(
    Activity activity,
    TTFullScreenVideoAd ad,
    InteractionCallback callback
  ) {
    ad.setFullScreenVideoAdInteractionListener(
      new TTFullScreenVideoAd.FullScreenVideoAdInteractionListener() {
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
        public void onSkippedVideo() {
          callback.onSkipped();
        }
      }
    );
    ad.showFullScreenVideoAd(activity);
  }
}
