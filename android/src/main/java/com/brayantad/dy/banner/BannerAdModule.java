package com.brayantad.dy.banner;

import android.util.Log;

import androidx.annotation.NonNull;

import com.brayantad.dy.DyADCore;
import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTNativeExpressAd;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.UiThreadUtil;

import java.util.List;

/**
 * Banner 广告预加载模块
 * 提供 Banner 广告的预加载功能，减少白屏时间
 */
public class BannerAdModule extends ReactContextBaseJavaModule {
  public static final String TAG = "BannerAdModule";
  private static ReactApplicationContext reactAppContext;

  // Banner 广告缓存
  private static TTNativeExpressAd bannerAdCache = null;
  private static String bannerAdCacheCodeId = null;
  private static long bannerAdCacheTime = 0;
  private static final long CACHE_VALID_DURATION = 5 * 60 * 1000; // 缓存有效期 5 分钟

  public BannerAdModule(ReactApplicationContext reactContext) {
    super(reactContext);
    reactAppContext = reactContext;
  }

  @NonNull
  @Override
  public String getName() {
    return TAG;
  }

  /**
   * 预加载 Banner 广告
   * 在组件渲染前调用，提前加载广告数据
   *
   * @param options 包含 codeid, adWidth, adHeight
   * @param promise 回调
   */
  @ReactMethod
  public void preloadBannerAd(ReadableMap options, final Promise promise) {
    String codeId = options.hasKey("codeid") ? options.getString("codeid") : null;
    int adWidth = options.hasKey("adWidth") ? options.getInt("adWidth") : 320;
    int adHeight = options.hasKey("adHeight") ? options.getInt("adHeight") : 50;

    if (codeId == null || codeId.isEmpty()) {
      promise.reject(TAG, "codeid is required");
      return;
    }

    // 检查 SDK 是否初始化
    if (DyADCore.TTAdSdk == null) {
      promise.reject(TAG, "TTAdSdk not initialized");
      return;
    }

    // 检查缓存是否有效
    if (hasValidCache(codeId)) {
      Log.d(TAG, "Using cached banner ad");
      promise.resolve(true);
      return;
    }

    // 清除旧缓存
    discardCache();

    // 创建广告请求参数
    AdSlot adSlot = new AdSlot.Builder()
      .setCodeId(codeId)
      .setSupportDeepLink(true)
      .setAdCount(1)
      .setExpressViewAcceptedSize(adWidth, adHeight)
      .build();

    // 请求广告
    DyADCore.TTAdSdk.loadBannerExpressAd(
      adSlot,
      new TTAdNative.NativeExpressAdListener() {
        @Override
        public void onError(int code, String message) {
          Log.d(TAG, "preloadBannerAd error: " + message);
          promise.reject(TAG, "preload banner ad error: " + message);
        }

        @Override
        public void onNativeExpressAdLoad(List<TTNativeExpressAd> ads) {
          Log.d(TAG, "preloadBannerAd success");
          if (ads == null || ads.isEmpty()) {
            promise.reject(TAG, "preload banner ad: no ad content");
            return;
          }

          TTNativeExpressAd ad = ads.get(0);
          UiThreadUtil.runOnUiThread(() -> {
            ad.setExpressInteractionListener(
              new TTNativeExpressAd.ExpressAdInteractionListener() {
                @Override
                public void onAdClicked(android.view.View view, int type) {}

                @Override
                public void onAdShow(android.view.View view, int type) {}

                @Override
                public void onRenderFail(android.view.View view, String msg, int code) {
                  Log.d(TAG, "preloadBannerAd render error: " + msg);
                  promise.reject(TAG, "preload banner ad render error: " + msg);
                }

                @Override
                public void onRenderSuccess(android.view.View view, float width, float height) {
                  bannerAdCache = ad;
                  bannerAdCacheCodeId = codeId;
                  bannerAdCacheTime = System.currentTimeMillis();
                  promise.resolve(true);
                }
              }
            );
            ad.render();
          });
        }
      }
    );
  }

  /**
   * 检查是否有有效的缓存广告
   *
   * @param codeId 广告位 ID
   * @return true 如果缓存有效
   */
  @ReactMethod
  public void hasPreloadedBannerAd(String codeId, Promise promise) {
    promise.resolve(hasValidCache(codeId));
  }

  /**
   * 获取缓存的广告（供 BannerAdView 使用）
   *
   * @param codeId 广告位 ID
   * @return 缓存的广告，如果没有则返回 null
   */
  public static TTNativeExpressAd getCachedBannerAd(String codeId) {
    if (hasValidCache(codeId)) {
      TTNativeExpressAd cachedAd = bannerAdCache;
      consumeCache();
      return cachedAd;
    }
    return null;
  }

  /**
   * 清除缓存的广告
   */
  @ReactMethod
  public void clearPreloadedBannerAd() {
    discardCache();
  }

  /**
   * 检查缓存是否有效
   */
  private static boolean hasValidCache(String codeId) {
    if (bannerAdCache == null || bannerAdCacheCodeId == null) {
      return false;
    }
    // 检查 codeId 是否匹配
    if (!bannerAdCacheCodeId.equals(codeId)) {
      return false;
    }
    // 检查缓存是否过期
    long currentTime = System.currentTimeMillis();
    return (currentTime - bannerAdCacheTime) < CACHE_VALID_DURATION;
  }

  /**
   * 清除缓存
   */
  private static void consumeCache() {
    bannerAdCache = null;
    bannerAdCacheCodeId = null;
    bannerAdCacheTime = 0;
  }

  private static void discardCache() {
    if (bannerAdCache != null) {
      bannerAdCache.destroy();
    }
    consumeCache();
  }
}
