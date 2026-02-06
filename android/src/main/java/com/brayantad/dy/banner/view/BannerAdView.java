package com.brayantad.dy.banner.view;

import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import com.brayantad.R;
import com.brayantad.dy.DyADCore;
import com.brayantad.dy.banner.BannerAdModule;
import com.brayantad.utils.Utils;
import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.TTAdDislike;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTNativeExpressAd;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.RCTEventEmitter;

public class BannerAdView extends RelativeLayout {
  private Activity mActivity;
  private ReactContext mReactContext;
  private String mCodeId;
  private AdSlot mAdSlot;
  private TTNativeExpressAd mBannerAd;

  private int mExpectedWidth = 0; // 宽度 dp，由外部设置（必填）
  private int mExpectedHeight = 0; // 高度 dp，由外部设置（必填），根据官方文档 Banner 广告高度不能为 0
  private boolean mIsAdLoading = false; // 防止重复加载广告

  public BannerAdView(ReactContext context) {
    super(context);
    mReactContext = context;
    mActivity = context.getCurrentActivity();

    inflate(context, R.layout.feed_view, this);
    Utils.setupLayoutHack(this);

    setVisibility(View.INVISIBLE);

    RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
      RelativeLayout.LayoutParams.MATCH_PARENT,
      mExpectedHeight
    );
    setLayoutParams(params);
  }

  public void setWidth(int width) {
    mExpectedWidth = width;
    showAd();
  }

  public void setHeight(int height) {
    mExpectedHeight = height;

    ViewGroup.LayoutParams params = getLayoutParams();
    if (params != null) {
      params.height = height;
      setLayoutParams(params);
    }

    showAd();
  }

  public void setCodeId(String codeId) {
    mCodeId = codeId;
    showAd();
  }

  /**
   * 设置可见性
   * @param visible true: 可见，false: 不可见
   */
  public void setVisibility(boolean visible) {
    if (visible) {
      // 触发加载，但暂不显示（等待渲染成功）
      showAd();
    } else {
      super.setVisibility(View.INVISIBLE);
    }
  }

  public void showAd() {
    // 参数校验
    if (mExpectedWidth <= 0 || mExpectedHeight <= 0 || mCodeId == null || mCodeId.isEmpty()) {
      return;
    }

    // 防止重复加载
    if (mIsAdLoading) {
      return;
    }

    // 检查 SDK 初始化
    if (DyADCore.TTAdSdk == null) {
      return;
    }

    // 在UI线程加载广告
    mIsAdLoading = true;
    runOnUiThread(this::loadBannerAd);
  }

  // 显示Banner广告
  private void loadBannerAd() {
    if (mBannerAd != null) {
      mBannerAd.destroy();
    }

    // 先检查是否有预加载的缓存广告
    TTNativeExpressAd cachedAd = BannerAdModule.getCachedBannerAd(mCodeId);
    if (cachedAd != null) {
      mBannerAd = cachedAd;
      showBannerAd(mBannerAd);
      mIsAdLoading = false;
      return;
    }

    // 没有缓存，正常加载
    // 创建广告请求参数AdSlot
    mAdSlot =
      new AdSlot.Builder()
        .setCodeId(mCodeId)
        .setSupportDeepLink(true)
        .setAdCount(1)
        .setExpressViewAcceptedSize(mExpectedWidth, mExpectedHeight)
        .build();

    DyADCore.TTAdSdk.loadBannerExpressAd(
      mAdSlot,
      new TTAdNative.NativeExpressAdListener() {

        @Override
        public void onError(int code, String message) {
          mIsAdLoading = false;
          String errorMsg = "Banner ad error: " + code + ", " + message;
          onAdError(errorMsg);
        }

        @Override
        public void onNativeExpressAdLoad(java.util.List<TTNativeExpressAd> ads) {
          if (ads == null || ads.isEmpty()) {
            mIsAdLoading = false;
            onAdError("Banner ad loaded but no content");
            return;
          }

          mIsAdLoading = false;
          mBannerAd = ads.get(0);
          showBannerAd(mBannerAd);
        }
      }
    );
  }

  // 显示广告
  private void showBannerAd(final TTNativeExpressAd ad) {
    Activity activity = mActivity != null ? mActivity : mReactContext.getCurrentActivity();
    if (activity == null) {
      mIsAdLoading = false;
      onAdError("Activity not ready");
      return;
    }
    mActivity = activity;
    activity.runOnUiThread(() -> {
      bindAdListener(ad);
      ad.render();
    });
  }

  // 绑定Banner express ================================
  private final void bindAdListener(TTNativeExpressAd ad) {
    final RelativeLayout mExpressContainer = findViewById(R.id.feed_container);
    if (mExpressContainer == null) {
      onAdError("feed_container not found");
      return;
    }

    ad.setExpressInteractionListener(
      new TTNativeExpressAd.ExpressAdInteractionListener() {

        @Override
        public void onAdClicked(View view, int type) {
          onAdClick();
        }

        @Override
        public void onAdShow(View view, int type) {
          BannerAdView.this.onAdShow();
        }

        @Override
        public void onRenderFail(View view, String msg, int code) {
          onAdError("渲染失败: " + msg);
        }

        @Override
        public void onRenderSuccess(View view, float width, float height) {
          mExpressContainer.removeAllViews();

          RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT
          );
          mExpressContainer.addView(view, params);

          // 更新容器高度
          ViewGroup.LayoutParams containerParams = mExpressContainer.getLayoutParams();
          if (containerParams != null) {
            containerParams.height = (int) height;
            mExpressContainer.setLayoutParams(containerParams);
          }

          // 更新父视图高度
          ViewGroup.LayoutParams viewParams = BannerAdView.this.getLayoutParams();
          if (viewParams != null) {
            viewParams.height = (int) height;
            BannerAdView.this.setLayoutParams(viewParams);
          }

          view.setVisibility(View.VISIBLE);
          mExpressContainer.setVisibility(View.VISIBLE);
          BannerAdView.this.setVisibility(View.VISIBLE);

          mExpressContainer.requestLayout();
          BannerAdView.this.requestLayout();

          onAdRenderSuccess((int) width, (int) height);
        }
      }
    );
    // dislike设置
    bindDislike(ad);
  }

  /**
   * 设置广告的不喜欢
   */
  private void bindDislike(TTNativeExpressAd ad) {
    ad.setDislikeCallback(
      mActivity,
      new TTAdDislike.DislikeInteractionCallback() {

        @Override
        public void onShow() {}

        @Override
        public void onSelected(int position, String value, boolean enforce) {
          RelativeLayout mExpressContainer = findViewById(R.id.feed_container);
          if (mExpressContainer != null) {
            mExpressContainer.removeAllViews();
          }
          onAdDismiss();
          onAdDislike(value);
        }

        @Override
        public void onCancel() {}
      }
    );
  }

  // 外部事件..
  private void sendEvent(String eventName, WritableMap event) {
    mReactContext
      .getJSModule(RCTEventEmitter.class)
      .receiveEvent(getId(), eventName, event);
  }

  public void onAdError(String message) {
    WritableMap event = Arguments.createMap();
    event.putString("message", message);
    sendEvent("onAdError", event);
  }

  public void onAdClick() {
    WritableMap event = Arguments.createMap();
    sendEvent("onAdClick", event);
  }

  public void onAdShow() {
    WritableMap event = Arguments.createMap();
    sendEvent("onAdShow", event);
  }

  public void onAdDismiss() {
    WritableMap event = Arguments.createMap();
    sendEvent("onAdDismiss", event);
  }

  public void onAdRenderSuccess(int width, int height) {
    WritableMap event = Arguments.createMap();
    event.putInt("width", width);
    event.putInt("height", height);
    sendEvent("onAdRenderSuccess", event);
  }

  public void onAdDislike(String reason) {
    WritableMap event = Arguments.createMap();
    event.putString("reason", reason);
    sendEvent("onAdDislike", event);
  }

  @Override
  protected void onDetachedFromWindow() {
    super.onDetachedFromWindow();
    if (mBannerAd != null) {
      mBannerAd.destroy();
      mBannerAd = null;
    }
  }

  @Override
  protected void onAttachedToWindow() {
    super.onAttachedToWindow();
    // 路由切换后重新挂载时，主动触发一次加载
    showAd();
  }
}
