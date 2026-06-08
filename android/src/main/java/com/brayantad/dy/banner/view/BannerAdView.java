package com.brayantad.dy.banner.view;

import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import com.brayantad.R;
import com.brayantad.core.AdResourcePool;
import com.brayantad.dy.DyADCore;
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
  private String mRequestId = "";
  private String mPreloadToken;
  private String mSource = "realtime";
  private long mRequestStartTime = 0;
  private AdSlot mAdSlot;
  private TTNativeExpressAd mBannerAd;

  private int mExpectedWidth = 0; // 宽度 dp，由外部设置（必填）
  private int mExpectedHeight = 0; // 高度 dp，由外部设置（必填），根据官方文档 Banner 广告高度不能为 0
  private boolean mIsAdLoading = false; // 防止重复加载广告
  private boolean mVisible = true;
  private boolean mHasRenderedAd = false;

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

  public void setRequestId(String requestId) {
    mRequestId = requestId == null ? "" : requestId;
  }

  public void setPreloadToken(String preloadToken) {
    mPreloadToken = preloadToken;
  }

  /**
   * 设置可见性
   * @param visible true: 可见，false: 不可见
   */
  public void setVisibility(boolean visible) {
    mVisible = visible;
    if (!visible) {
      super.setVisibility(View.INVISIBLE);
      return;
    }
    if (canReuseRenderedAd()) {
      super.setVisibility(View.VISIBLE);
      return;
    }
    if (mHasRenderedAd && mBannerAd != null) {
      showBannerAd(mBannerAd);
      return;
    }
    // 仅在没有可复用广告实例时才加载
    showAd();
  }

  public void showAd() {
    if (!mVisible) {
      super.setVisibility(View.INVISIBLE);
      return;
    }
    if (canReuseRenderedAd()) {
      super.setVisibility(View.VISIBLE);
      return;
    }
    if (mHasRenderedAd && mBannerAd != null) {
      showBannerAd(mBannerAd);
      return;
    }
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
    mRequestStartTime = System.currentTimeMillis();
    emitV2Event("loading", null, 0, 0);
    runOnUiThread(this::loadBannerAd);
  }

  // 显示Banner广告
  private void loadBannerAd() {
    if (mBannerAd != null) {
      mBannerAd.destroy();
    }

    // 先检查是否有预加载的缓存广告
    AdResourcePool.Entry pooledEntry = AdResourcePool.consume(
      mPreloadToken,
      "banner",
      mCodeId,
      mExpectedWidth,
      mExpectedHeight
    );
    TTNativeExpressAd cachedAd =
      pooledEntry != null && pooledEntry.resource instanceof TTNativeExpressAd
        ? (TTNativeExpressAd) pooledEntry.resource
        : null;
    if (cachedAd != null) {
      mSource = "preloaded";
      emitV2Event("loaded", null, 0, 0);
      mBannerAd = cachedAd;
      mIsAdLoading = false;
      bindAdListener(mBannerAd);
      if (mBannerAd.getExpressAdView() != null) {
        mHasRenderedAd = true;
        attachRenderedAdView(mBannerAd.getExpressAdView(), mExpectedWidth, mExpectedHeight);
        onAdRenderSuccess(mExpectedWidth, mExpectedHeight);
      } else {
        showBannerAd(mBannerAd);
      }
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
          mSource = "realtime";
          emitV2Event("loaded", null, 0, 0);
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
      emitV2Event("rendering", null, 0, 0);
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
          mHasRenderedAd = true;
          attachRenderedAdView(view, (int) width, (int) height);
          onAdRenderSuccess((int) width, (int) height);
          emitV2Event("presented", null, (int) width, (int) height);
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
    emitV2Event("terminal", message, 0, 0);
    WritableMap event = Arguments.createMap();
    event.putString("message", message);
    sendEvent("onAdError", event);
  }

  public void onAdClick() {
    emitV2Event("presented", "click", null, 0, 0);
    WritableMap event = Arguments.createMap();
    sendEvent("onAdClick", event);
  }

  public void onAdShow() {
    WritableMap event = Arguments.createMap();
    sendEvent("onAdShow", event);
  }

  public void onAdDismiss() {
    emitV2Event("terminal", null, 0, 0);
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

  private void emitV2Event(String state, String errorMessage, int width, int height) {
    emitV2Event(state, null, errorMessage, width, height);
  }

  private void emitV2Event(
    String state,
    String action,
    String errorMessage,
    int width,
    int height
  ) {
    if (mRequestId.isEmpty()) {
      return;
    }
    WritableMap event = Arguments.createMap();
    event.putString("requestId", mRequestId);
    event.putString("format", "banner");
    event.putString("slotId", mCodeId == null ? "" : mCodeId);
    event.putString("state", state);
    if (action != null) {
      event.putString("action", action);
    }
    event.putString("source", mSource);
    event.putDouble(
      "elapsedMs",
      mRequestStartTime > 0 ? System.currentTimeMillis() - mRequestStartTime : 0
    );
    if (width > 0) {
      event.putInt("width", width);
    }
    if (height > 0) {
      event.putInt("height", height);
    }
    if (errorMessage != null) {
      WritableMap error = Arguments.createMap();
      error.putString("code", "BANNER_ERROR");
      error.putString("message", errorMessage);
      event.putMap("error", error);
    }
    sendEvent("onAdEvent", event);
  }

  public void destroy() {
    if (mBannerAd != null) {
      mBannerAd.destroy();
      mBannerAd = null;
    }
    mHasRenderedAd = false;
    mIsAdLoading = false;
  }

  @Override
  protected void onDetachedFromWindow() {
    super.onDetachedFromWindow();
    super.setVisibility(View.INVISIBLE);
  }

  @Override
  protected void onAttachedToWindow() {
    super.onAttachedToWindow();
    if (!mVisible) {
      super.setVisibility(View.INVISIBLE);
      return;
    }
    if (canReuseRenderedAd()) {
      super.setVisibility(View.VISIBLE);
      return;
    }
    if (mHasRenderedAd && mBannerAd != null) {
      showBannerAd(mBannerAd);
      return;
    }
    // 路由切换后重新挂载时，仅在无可复用实例时才触发加载
    showAd();
  }

  private boolean canReuseRenderedAd() {
    if (!mHasRenderedAd || mBannerAd == null) {
      return false;
    }
    RelativeLayout container = findViewById(R.id.feed_container);
    return container != null && container.getChildCount() > 0;
  }

  private void attachRenderedAdView(View adView, int width, int height) {
    final RelativeLayout expressContainer = findViewById(R.id.feed_container);
    if (expressContainer == null || adView == null) {
      onAdError("feed_container not found");
      return;
    }

    expressContainer.removeAllViews();
    if (adView.getParent() instanceof ViewGroup) {
      ((ViewGroup) adView.getParent()).removeView(adView);
    }

    RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
      RelativeLayout.LayoutParams.MATCH_PARENT,
      RelativeLayout.LayoutParams.WRAP_CONTENT
    );
    expressContainer.addView(adView, params);

    int effectiveHeight = height > 0 ? height : mExpectedHeight;

    ViewGroup.LayoutParams containerParams = expressContainer.getLayoutParams();
    if (containerParams != null) {
      containerParams.height = effectiveHeight;
      expressContainer.setLayoutParams(containerParams);
    }

    ViewGroup.LayoutParams viewParams = BannerAdView.this.getLayoutParams();
    if (viewParams != null) {
      viewParams.height = effectiveHeight;
      BannerAdView.this.setLayoutParams(viewParams);
    }

    adView.setVisibility(View.VISIBLE);
    expressContainer.setVisibility(View.VISIBLE);
    BannerAdView.this.setVisibility(View.VISIBLE);

    expressContainer.requestLayout();
    BannerAdView.this.requestLayout();
  }
}
