package com.brayantad.dy.feedAd.view;

import static com.bytedance.sdk.openadsdk.TTAdLoadType.PRELOAD;
import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

import android.app.Activity;
import android.util.Log;
import android.view.View;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;

import com.brayantad.R;
import com.brayantad.core.AdResourcePool;
import com.brayantad.dy.DyADCore;
import com.brayantad.utils.DislikeDialog;
import com.brayantad.utils.Utils;
import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.DislikeInfo;
import com.bytedance.sdk.openadsdk.FilterWord;
import com.bytedance.sdk.openadsdk.TTAdConstant;
import com.bytedance.sdk.openadsdk.TTAdDislike;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTAppDownloadListener;
import com.bytedance.sdk.openadsdk.TTNativeExpressAd;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.RCTEventEmitter;

import java.util.List;

public class FeedAdView extends RelativeLayout {
  // 信息流广告
  private static final String TAG = "FeedAd";

  private Activity mContext;
  private ReactContext reactContext;
  private String _codeid = "";
  private String mRequestId = "";
  private String mPreloadToken;
  private String mSource = "realtime";
  private AdSlot adSlot;

  private int _expectedWidth = 375;
  private int _expectedHeight = 0; // 高度0 自适应
  private long requestStartTime = 0;
  private boolean mHasShowDownloadActive = false;
  private boolean mIsAdLoading = false;
  private boolean mVisible = true;
  private boolean mHasRenderedAd = false;
  private boolean mHasPresentedAd = false;
  private boolean mPendingPresentation = false;
  private final Runnable mShowAdRunnable = this::showAdNow;

  // 当前展示的广告实例，用于资源释放
  private TTNativeExpressAd mCurrentAd;

  public FeedAdView(ReactContext context) {
    super(context);
    mContext = context.getCurrentActivity();
    reactContext = context;
    //开始展开
    inflate(context, R.layout.feed_view, this);

    // 初始隐藏容器，避免白屏闪现
    setVisibility(View.INVISIBLE);

    // 这个函数很关键，不然不能触发再次渲染，让 view 在 RN 里渲染成功!!
    Utils.setupLayoutHack(this);
  }

  public void setWidth(int width) {
    Log.d(TAG, "setCodeId = " + _codeid + ", setWidth:" + width);
    _expectedWidth = width;

    scheduleShowAd();
  }

  public void setCodeId(String codeId) {
    Log.d(TAG, "setCodeId: " + codeId + ", _expectedWidth:" + _expectedWidth);
    _codeid = codeId;
    scheduleShowAd();
  }

  public void setRequestId(String requestId) {
    mRequestId = requestId == null ? "" : requestId;
    scheduleShowAd();
  }

  public void setPreloadToken(String preloadToken) {
    mPreloadToken = preloadToken;
    scheduleShowAd();
  }

  public void setVisible(boolean visible) {
    mVisible = visible;
    if (!visible) {
      removeCallbacks(mShowAdRunnable);
      super.setVisibility(View.INVISIBLE);
      return;
    }
    if (canReuseRenderedAd()) {
      super.setVisibility(View.VISIBLE);
      return;
    }
    if (mHasRenderedAd && mCurrentAd != null) {
      _showTTAd(mCurrentAd);
      return;
    }
    scheduleShowAd();
  }

  private void scheduleShowAd() {
    removeCallbacks(mShowAdRunnable);
    post(mShowAdRunnable);
  }

  private void showAdNow() {
    if (!mVisible) {
      super.setVisibility(View.INVISIBLE);
      return;
    }
    if (canReuseRenderedAd()) {
      super.setVisibility(View.VISIBLE);
      return;
    }
    if (mHasRenderedAd && mCurrentAd != null) {
      _showTTAd(mCurrentAd);
      return;
    }
    Log.d(TAG, "showAd: width:" + _expectedWidth + " codeid:" + _codeid);

    // 显示广告
    if (_expectedWidth == 0 || _codeid.isEmpty()) {
      // 广告宽度未设置或 code id 未设置，停止显示广告
      return;
    }
    if (mIsAdLoading) {
      return;
    }
    if (DyADCore.TTAdSdk == null) {
      onAdError("TTAdSdk not initialized");
      return;
    }
    Activity activity = mContext != null ? mContext : reactContext.getCurrentActivity();
    if (activity == null) {
      onAdError("Activity not ready");
      return;
    }
    mContext = activity;
    mIsAdLoading = true;
    mHasRenderedAd = false;
    mHasPresentedAd = false;
    mPendingPresentation = false;
    requestStartTime = System.currentTimeMillis();
    Log.d(
      TAG,
      "请求广告: requestId=" + mRequestId +
        ", slotId=" + _codeid +
        ", expectedWidth=" + _expectedWidth + "dp" +
        ", view=" + getWidth() + "x" + getHeight() + "px"
    );
    emitV2Event("loading", null, 0, 0);

    AdResourcePool.Entry pooledEntry = AdResourcePool.consume(
      mPreloadToken,
      "feed",
      _codeid,
      _expectedWidth,
      0
    );
    TTNativeExpressAd cachedAd =
      pooledEntry != null && pooledEntry.resource instanceof TTNativeExpressAd
        ? (TTNativeExpressAd) pooledEntry.resource
        : null;
    if (cachedAd != null) {
      mSource = "preloaded";
      emitV2Event("loaded", null, 0, 0);
      if (mCurrentAd != null) {
        mCurrentAd.destroy();
      }
      mCurrentAd = cachedAd;
      _showTTAd(cachedAd);
      return;
    }
    // 信息流广告原来不能提前预加载，很容易出现超时，必须当场加载
    // sdk里很容易出现 message send to dead thread ... 肯定有些资源线程依赖！
    runOnUiThread(
      () -> {
        loadTTFeedAd();
      }
    );
  }

  // 显示头条的信息流广告
  public void loadTTFeedAd() {
    // 创建广告请求参数AdSlot,具体参数含义参考文档 modules.add(new Interaction(reactContext));
    adSlot =
      new AdSlot.Builder()
        .setCodeId(_codeid) // 广告位id
        .setSupportDeepLink(true)
        .setAdCount(1) // 请求广告数量为1到3条
        .setExpressViewAcceptedSize(_expectedWidth, _expectedHeight) // 期望模板广告view的size,单位dp,高度0自适应
        .setImageAcceptedSize(640, 320)
        .setNativeAdType(AdSlot.TYPE_INTERACTION_AD)
        .setAdLoadType(PRELOAD)
        .build();

    // 请求广告，对请求回调的广告作渲染处理
    final FeedAdView _this = this;
    DyADCore.TTAdSdk.loadNativeExpressAd(
      adSlot,
      new TTAdNative.NativeExpressAdListener() {

        @Override
        public void onError(int code, String message) {
          mIsAdLoading = false;
          message =
            "错误结果 loadNativeExpressAd onAdError: " + code + ", " + message;
          // TToast.show(getContext(), message);
          Log.d(TAG, message);
          _this.onAdError(message);
        }

        @Override
        public void onNativeExpressAdLoad(List<TTNativeExpressAd> ads) {
          Log.d(TAG, "onNativeExpressAdLoad: !!!");
          if (ads == null || ads.isEmpty()) {
            mIsAdLoading = false;
            _this.onAdError("加载成功无广告内容");
            return;
          }

          TTNativeExpressAd ad = ads.get(0);
          if (_this.mCurrentAd != null) {
            _this.mCurrentAd.destroy();
          }
          // 保存广告引用，用于后续销毁
          _this.mCurrentAd = ad;
          _this.mSource = "realtime";
          _this.emitV2Event("loaded", null, 0, 0);
          _showTTAd(ad);
        }
      }
    );
  }

  // 显示广告
  private void _showTTAd(final TTNativeExpressAd ad) {
    Activity activity = mContext != null ? mContext : reactContext.getCurrentActivity();
    if (activity == null) {
      mIsAdLoading = false;
      onAdError("Activity not ready");
      return;
    }
    mContext = activity;
    activity.runOnUiThread(
      () -> {
        bindAdListener(ad);
        emitV2Event("rendering", null, 0, 0);
        ad.render();
      }
    );
  }

  // 绑定Feed express ================================
  private final void bindAdListener(TTNativeExpressAd ad) {
    final FeedAdView _this = this;
    final RelativeLayout mExpressContainer = findViewById(R.id.feed_container);
    ad.setExpressInteractionListener(
      new TTNativeExpressAd.ExpressAdInteractionListener() {

        @Override
        public void onAdClicked(View view, int type) {
          if (ad != mCurrentAd) {
            return;
          }
          Log.d(TAG, "feed ad clicked");
          // TToast.show(mContext, "广告被点击");
          onAdClick();
        }

        @Override
        public void onAdShow(View view, int type) {
          if (ad != mCurrentAd || mHasPresentedAd) {
            return;
          }
          if (!mHasRenderedAd) {
            mPendingPresentation = true;
            return;
          }
          mHasPresentedAd = true;
          Log.d(
            TAG,
            "render onAdShow:" + (System.currentTimeMillis() - requestStartTime)
          );
          emitV2Event("presented", null, 0, 0);
        }

        @Override
        public void onRenderFail(View view, String msg, int code) {
          if (ad != mCurrentAd) {
            return;
          }
          mIsAdLoading = false;
          Log.d(TAG, "render fail:" + (System.currentTimeMillis() - requestStartTime));
          _this.onAdError("加载成功 渲染失败 code:" + code);
        }

        @Override
        public void onRenderSuccess(View view, float width, float height) {
          if (ad != mCurrentAd || mHasRenderedAd) {
            return;
          }
          Log.d(
            TAG,
            "渲染成功: requestId=" + mRequestId +
              ", sdk=" + width + "x" + height + "dp" +
              ", view=" + getWidth() + "x" + getHeight() + "px"
          );
          mIsAdLoading = false;
          mHasRenderedAd = true;
          RelativeLayout mExpressContainer = findViewById(R.id.feed_container);
          if (mExpressContainer != null) {
            mExpressContainer.removeAllViews();
            mExpressContainer.addView(view);
          }
          FeedAdView.this.setVisibility(mVisible ? View.VISIBLE : View.INVISIBLE);
          onAdLayout((int) width, (int) height);
          emitV2Event("rendered", null, (int) width, (int) height);
          if (mPendingPresentation && !mHasPresentedAd) {
            mPendingPresentation = false;
            mHasPresentedAd = true;
            emitV2Event("presented", null, (int) width, (int) height);
          }
        }
      }
    );
    bindDislike(ad, true);
    if (ad.getInteractionType() != TTAdConstant.INTERACTION_TYPE_DOWNLOAD) {
      return;
    }
    // 可选，下载监听设置
    ad.setDownloadListener(
      new TTAppDownloadListener() {

        @Override
        public void onIdle() {
          // TToast.show(getContext(), "点击开始下载", Toast.LENGTH_LONG);
        }

        @Override
        public void onDownloadActive(
          long totalBytes,
          long currBytes,
          String fileName,
          String appName
        ) {
          if (!mHasShowDownloadActive) {
            mHasShowDownloadActive = true;
            // TToast.show(getContext(), "下载中，点击暂停", Toast.LENGTH_LONG);
          }
        }

        @Override
        public void onDownloadPaused(
          long totalBytes,
          long currBytes,
          String fileName,
          String appName
        ) {
          // TToast.show(getContext(), "下载暂停，点击继续", Toast.LENGTH_LONG);
        }

        @Override
        public void onDownloadFailed(
          long totalBytes,
          long currBytes,
          String fileName,
          String appName
        ) {
          // TToast.show(getContext(), "下载失败，点击重新下载", Toast.LENGTH_LONG);
        }

        @Override
        public void onInstalled(String fileName, String appName) {
          // TToast.show(getContext(), "安装完成，点击图片打开", Toast.LENGTH_LONG);
        }

        @Override
        public void onDownloadFinished(
          long totalBytes,
          String fileName,
          String appName
        ) {
          // TToast.show(getContext(), "点击安装", Toast.LENGTH_LONG);
        }
      }
    );
  }

  /**
   * 设置广告的不喜欢，开发者可自定义样式
   *
   * @param ad
   * @param customStyle 是否自定义样式，true:样式自定义
   */
  private void bindDislike(TTNativeExpressAd ad, boolean customStyle) {
    final RelativeLayout mExpressContainer = findViewById(R.id.feed_container);
    if (customStyle) {
      // 使用自定义样式
      //            List<FilterWord> words = ad.getFilterWords();
      //            if (words == null || words.isEmpty()) {
      //                return;
      //            }
      DislikeInfo dislikeInfo = ad.getDislikeInfo();
      if (
        dislikeInfo == null ||
        dislikeInfo.getFilterWords() == null ||
        dislikeInfo.getFilterWords().isEmpty()
      ) {
        return;
      }

      final DislikeDialog dislikeDialog = getDislikeDialog(dislikeInfo, mExpressContainer);
      ad.setDislikeDialog(dislikeDialog);
      return;
    }
    // 使用默认个性化模板中默认dislike弹出样式
    ad.setDislikeCallback(
      mContext,
      new TTAdDislike.DislikeInteractionCallback() {

        @Override
        public void onShow() {}

        @Override
        public void onSelected(int position, String value, boolean enforce) {
          // TToast.show(mContext, "点击 " + value);
          // 用户选择不喜欢原因后，移除广告展示
          mExpressContainer.removeAllViews();
          onAdClose(value);
        }

        @Override
        public void onCancel() {
          // TToast.show(mContext, "点击取消 ");
        }
      }
    );
  }

  @NonNull
  private DislikeDialog getDislikeDialog(DislikeInfo dislikeInfo, RelativeLayout mExpressContainer) {
    final DislikeDialog dislikeDialog = new DislikeDialog(
      getContext(),
      dislikeInfo.getFilterWords()
    );
    dislikeDialog.setOnDislikeItemClick(
      new DislikeDialog.OnDislikeItemClick() {

        @Override
        public void onItemClick(FilterWord filterWord) {
          // 屏蔽广告
          // TToast.show(mContext, "点击=" + filterWord.getName());
          // 用户选择不喜欢原因后，移除广告展示
          mExpressContainer.removeAllViews();
          onAdClose(filterWord.getName());
        }
      }
    );
    return dislikeDialog;
  }

  // 外部事件..
  public void onAdError(String message) {
    emitV2Event("terminal", message, 0, 0);
    WritableMap event = Arguments.createMap();
    event.putString("message", message);
    reactContext
      .getJSModule(RCTEventEmitter.class)
      .receiveEvent(getId(), "onAdError", event);
  }

  public void onAdClick() {
    emitV2Event("presented", "click", null, 0, 0);
    WritableMap event = Arguments.createMap();
    reactContext
      .getJSModule(RCTEventEmitter.class)
      .receiveEvent(getId(), "onAdClick", event);
  }

  public void onAdClose(String reason) {
    Log.d(TAG, "onAdClose: " + reason);
    mHasRenderedAd = false;
    super.setVisibility(View.INVISIBLE);
    emitV2Event("terminal", null, 0, 0);
    WritableMap event = Arguments.createMap();
    event.putString("reason", reason);
    reactContext
      .getJSModule(RCTEventEmitter.class)
      .receiveEvent(getId(), "onAdClose", event);
  }

  public void onAdLayout(int width, int height) {
    Log.d(TAG, "onAdLayout: " + width + ", " + height);
    WritableMap event = Arguments.createMap();
    event.putInt("width", width);
    event.putInt("height", height);
    reactContext
      .getJSModule(RCTEventEmitter.class)
      .receiveEvent(getId(), "onAdLayout", event);
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
    event.putString("format", "feed");
    event.putString("slotId", _codeid);
    event.putString("state", state);
    if (action != null) {
      event.putString("action", action);
    }
    event.putString("source", mSource);
    event.putDouble(
      "elapsedMs",
      requestStartTime > 0 ? System.currentTimeMillis() - requestStartTime : 0
    );
    if (width > 0) {
      event.putInt("width", width);
    }
    if (height > 0) {
      event.putInt("height", height);
    }
    if (errorMessage != null) {
      WritableMap error = Arguments.createMap();
      error.putString("code", "FEED_ERROR");
      error.putString("message", errorMessage);
      event.putMap("error", error);
    }
    reactContext
      .getJSModule(RCTEventEmitter.class)
      .receiveEvent(getId(), "onAdEvent", event);
  }

  /**
   * 销毁广告资源，释放内存
   * 在组件卸载或需要重新加载广告时调用
   */
  public void destroy() {
    Log.d(TAG, "destroy: 释放广告资源");
    mIsAdLoading = false;
    mHasRenderedAd = false;
    mHasPresentedAd = false;
    mPendingPresentation = false;
    removeCallbacks(mShowAdRunnable);
    // 清空广告容器
    final RelativeLayout mExpressContainer = findViewById(R.id.feed_container);
    if (mExpressContainer != null) {
      mExpressContainer.removeAllViews();
    }
    // 销毁广告实例，释放原生资源
    if (mCurrentAd != null) {
      mCurrentAd.destroy();
      mCurrentAd = null;
    }
    // 移除所有子视图
    removeAllViews();
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
    if (mHasRenderedAd && mCurrentAd != null) {
      _showTTAd(mCurrentAd);
      return;
    }
    // 路由切换后重新挂载时，仅在无可复用实例时才触发加载
    scheduleShowAd();
  }

  private boolean canReuseRenderedAd() {
    if (!mHasRenderedAd || mCurrentAd == null) {
      return false;
    }
    final RelativeLayout mExpressContainer = findViewById(R.id.feed_container);
    return mExpressContainer != null && mExpressContainer.getChildCount() > 0;
  }
}
