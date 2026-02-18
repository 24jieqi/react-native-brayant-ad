package com.brayantad.dy.splash;

import android.app.Activity;
import android.content.Intent;
import android.util.DisplayMetrics;
import android.util.Log;

import androidx.annotation.NonNull;

import com.brayantad.dy.DyADCore;
import com.brayantad.dy.splash.activity.SplashActivity;
import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.CSJAdError;
import com.bytedance.sdk.openadsdk.CSJSplashAd;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTAdSdk;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import static com.bytedance.sdk.openadsdk.TTAdLoadType.PRELOAD;

// 开屏广告
public class SplashAdModule extends ReactContextBaseJavaModule {

  String TAG = "SplashAd";
  ReactApplicationContext mContext;
  // 开屏广告预加载超时时间
  private static final int PRELOAD_TIME_OUT = 5000;

  public SplashAdModule(@NonNull ReactApplicationContext reactContext) {
    super(reactContext);
    mContext = reactContext;
  }

  @NonNull
  @Override
  public String getName() {
    return TAG;
  }

  /**
   * 预加载开屏广告
   * 在应用启动时调用，提前加载广告，避免展示时出现白屏
   */
  @ReactMethod
  public void preloadSplashAd(ReadableMap options, Promise promise) {
    String codeid = options.hasKey("codeid") ? options.getString("codeid") : null;

    if (codeid == null || codeid.isEmpty()) {
      promise.reject("INVALID_CODEID", "广告位ID不能为空");
      return;
    }

    // 检查是否已有有效预加载
    if (DyADCore.splashAd != null && isPreloadValid()) {
      Log.d(TAG, "预加载广告已存在且有效，无需重新加载");
      DyADCore.splashPreloadStatus = DyADCore.SPLASH_PRELOAD_SUCCESS;
      WritableMap result = Arguments.createMap();
      result.putBoolean("success", true);
      result.putString("message", "使用已预加载的广告");
      promise.resolve(result);
      return;
    }

    // 检查SDK是否初始化
    if (DyADCore.TTAdSdk == null || !TTAdSdk.isSdkReady()) {
      promise.reject("SDK_NOT_READY", "广告SDK未初始化");
      return;
    }

    // 设置预加载状态为加载中
    DyADCore.splashPreloadStatus = DyADCore.SPLASH_PRELOAD_LOADING;

    TTAdNative mTTAdNative = DyADCore.TTAdSdk;

    // 创建开屏广告请求参数
    int[] expressSizeDp = resolveExpressViewSizeDp();
    AdSlot adSlot = new AdSlot.Builder()
      .setCodeId(codeid)
      .setSupportDeepLink(true)
      .setExpressViewAcceptedSize(expressSizeDp[0], expressSizeDp[1])
      .setAdLoadType(PRELOAD)
      .build();

    // 请求广告
    mTTAdNative.loadSplashAd(
      adSlot,
      new TTAdNative.CSJSplashAdListener() {
        @Override
        public void onSplashLoadSuccess(CSJSplashAd csjSplashAd) {
          // 素材加载成功
        }

        @Override
        public void onSplashLoadFail(CSJAdError csjAdError) {
          Log.d(TAG, "预加载开屏广告失败:" + csjAdError);
          DyADCore.splashPreloadStatus = DyADCore.SPLASH_PRELOAD_FAIL;
          DyADCore.splashAd = null;

          // 发送预加载失败事件
          WritableMap eventParams = Arguments.createMap();
          eventParams.putString("error", csjAdError != null ? csjAdError.getMsg() : "未知错误");
          sendEvent("SplashAd-onPreloadFail", eventParams);

          promise.reject("PRELOAD_FAIL", csjAdError != null ? csjAdError.getMsg() : "预加载失败");
        }

        @Override
        public void onSplashRenderSuccess(CSJSplashAd csjSplashAd) {
          Log.d(TAG, "预加载开屏广告成功");
          DyADCore.splashAd = csjSplashAd;
          DyADCore.splashPreloadStatus = DyADCore.SPLASH_PRELOAD_SUCCESS;
          DyADCore.splashPreloadTime = System.currentTimeMillis();

          // 发送预加载成功事件
          WritableMap eventParams = Arguments.createMap();
          eventParams.putBoolean("success", true);
          sendEvent("SplashAd-onPreloadSuccess", eventParams);

          WritableMap result = Arguments.createMap();
          result.putBoolean("success", true);
          result.putString("message", "预加载成功");
          promise.resolve(result);
        }

        @Override
        public void onSplashRenderFail(CSJSplashAd csjSplashAd, CSJAdError csjAdError) {
          Log.d(TAG, "预加载开屏广告渲染失败:" + csjAdError);
          DyADCore.splashPreloadStatus = DyADCore.SPLASH_PRELOAD_FAIL;
          DyADCore.splashAd = null;

          // 发送预加载失败事件
          WritableMap eventParams = Arguments.createMap();
          eventParams.putString("error", csjAdError != null ? csjAdError.getMsg() : "渲染失败");
          sendEvent("SplashAd-onPreloadFail", eventParams);

          promise.reject("RENDER_FAIL", csjAdError != null ? csjAdError.getMsg() : "渲染失败");
        }
      },
      PRELOAD_TIME_OUT
    );
  }

  /**
   * 检查预加载的广告是否仍然有效（5分钟有效期）
   */
  private boolean isPreloadValid() {
    if (DyADCore.splashPreloadTime == 0) return false;
    long elapsed = System.currentTimeMillis() - DyADCore.splashPreloadTime;
    return elapsed < DyADCore.SPLASH_PRELOAD_VALID_DURATION;
  }

  private int[] resolveExpressViewSizeDp() {
    DisplayMetrics metrics = mContext.getResources().getDisplayMetrics();
    int widthDp = Math.round(metrics.widthPixels / metrics.density);
    int heightDp = Math.round(metrics.heightPixels / metrics.density);

    // 按屏幕尺寸动态设置模板大小，避免固定超大尺寸导致低填充
    widthDp = Math.max(widthDp, 320);
    heightDp = Math.max(heightDp, 480);

    return new int[]{widthDp, heightDp};
  }

  /**
   * 检查是否有预加载的广告可用
   */
  @ReactMethod
  public void hasPreloadedAd(Promise promise) {
    boolean hasAd = DyADCore.splashAd != null && isPreloadValid();
    WritableMap result = Arguments.createMap();
    result.putBoolean("hasAd", hasAd);
    result.putInt("status", DyADCore.splashPreloadStatus);
    promise.resolve(result);
  }

  /**
   * 清除预加载的广告缓存
   */
  @ReactMethod
  public void clearPreloadedAd() {
    DyADCore.splashAd = null;
    DyADCore.splashPreloadStatus = DyADCore.SPLASH_PRELOAD_IDLE;
    DyADCore.splashPreloadTime = 0;
  }

  private void sendEvent(String eventName, WritableMap params) {
    if (mContext != null && mContext.hasActiveCatalystInstance()) {
      mContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
    }
  }

  @ReactMethod
  public void loadSplashAd(ReadableMap options) {
    String codeid = options.hasKey("codeid") ? options.getString("codeid") : null;
    String anim = options.hasKey("anim") ? options.getString("anim") : "default";
    // 设置开屏广告启动动画
    setAnim(anim);
    // 默认走穿山甲
    startSplash(codeid);
  }

  private void startSplash(String codeid) {
    Intent intent = new Intent(mContext, SplashActivity.class);
    try {
      intent.putExtra("codeid", codeid);
      final Activity context = getCurrentActivity();
      context.startActivity(intent);

      if (DyADCore.splashAd_anim_in != -1) {
        // 实现广告开启跳转 Activity 动画设置
        context.overridePendingTransition(DyADCore.splashAd_anim_in, DyADCore.splashAd_anim_out);
      }

    } catch (Exception e) {
      e.printStackTrace();
    }
  }





  private void setAnim(String animStr) {
    switch (animStr) {
      case "catalyst":
        DyADCore.splashAd_anim_in = 0;
        DyADCore.splashAd_anim_out = 0;
        break;
      case "none":
        DyADCore.splashAd_anim_in = 0;
        DyADCore.splashAd_anim_out = 0;
        break;
      case "slide":
        DyADCore.splashAd_anim_in = android.R.anim.slide_in_left;
        DyADCore.splashAd_anim_out = android.R.anim.slide_out_right;
        break;
      case "fade":
        DyADCore.splashAd_anim_in = android.R.anim.fade_in;
        DyADCore.splashAd_anim_out = android.R.anim.fade_in;
        break;
      default:
        DyADCore.splashAd_anim_in = 0;
        DyADCore.splashAd_anim_out = 0;
        break;
    }
  }

}
