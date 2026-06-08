package com.brayantad;

import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import com.brayantad.core.AdResourcePool;
import com.brayantad.dy.DyADCore;
import com.brayantad.dy.splash.activity.SplashActivity;
import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.CSJAdError;
import com.bytedance.sdk.openadsdk.CSJSplashAd;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTAdSdk;
import com.bytedance.sdk.openadsdk.TTNativeExpressAd;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class AdManager extends ReactContextBaseJavaModule {
  public static ReactApplicationContext reactAppContext;
  public static final String TAG = "AdManager";
  private static final Map<String, Promise> splashPromises = new ConcurrentHashMap<>();

  public AdManager(ReactApplicationContext reactContext) {
    super(reactContext);
    reactAppContext = reactContext;
  }

  @NonNull
  @Override
  public String getName() {
    return TAG;
  }
  @ReactMethod
  public void init(ReadableMap options, Promise promise) {
    //默认头条穿山甲
    DyADCore.tt_appid = options.hasKey("appid") ? options.getString("appid") : DyADCore.tt_appid;
    DyADCore.debug = options.hasKey("debug") ? options.getBoolean("debug") : DyADCore.debug;
    DyADCore.rewardName = options.hasKey("reward") ? options.getString("reward") : DyADCore.rewardName;
    DyADCore.rewardAmount = options.hasKey("amount") ? options.getInt("amount") : DyADCore.rewardAmount;
    DyADCore.appName = options.hasKey("app") ? options.getString("app") : DyADCore.appName;

    if (DyADCore.tt_appid != null) {
      DyADCore.initSdk(reactAppContext, DyADCore.tt_appid, DyADCore.debug);
      boolean sdkReady = TTAdSdk.isSdkReady();
      if (!sdkReady) {
        TTAdSdk.start(new TTAdSdk.Callback() {
          @Override
          public void success() {
            Log.i(TAG, "success: " + TTAdSdk.isSdkReady());
            promise.resolve(true);
          }

          @Override
          public void fail(int code, String msg) {
            Log.i(TAG, "fail:  code = " + code + " msg = " + msg);
            promise.reject(TAG, "fail:  code = " + code + " msg = " + msg);
          }
        });
        return;
      }
      promise.resolve(true);
      return;
//      if (options.hasKey("codeid_reward_video")) {
//        DyADCore.codeid_reward_video = options.getString("codeid_reward_video");
//        //提前加载
//        assert DyADCore.codeid_reward_video != null;
//
//        if(!sdkReady) {
//          TTAdSdk.start(new TTAdSdk.Callback() {
//            @Override
//            public void success() {
//              Log.i(TAG, "success: " + TTAdSdk.isSdkReady());
//              RewardActivity.loadAd(
//                DyADCore.codeid_reward_video,
//                () -> {
//                  Log.d(
//                    TAG,
//                    "提前加载 成功 codeid_reward_video " +
//                      DyADCore.codeid_reward_video
//                  );
//                }
//              );
//            }
//
//            @Override
//            public void fail(int code, String msg) {
//              Log.i(TAG, "fail:  code = " + code + " msg = " + msg);
//            }
//            private static TTAdConfig buildConfig(Context context) {
//              return new TTAdConfig.Builder()
//                .appId(DyADCore.tt_appid)//应用ID
//                .supportMultiProcess(true)//开启多进程
//                .build();
//            }
//          });
//        }
//      }
    }
    promise.reject(TAG, "appid is required");
  }

  @ReactMethod
  public void initializeAdSdk(ReadableMap options, Promise promise) {
    if (options.hasKey("allowInitialization") && !options.getBoolean("allowInitialization")) {
      promise.resolve(false);
      return;
    }

    String appId = options.hasKey("appId") ? options.getString("appId") : null;
    if (appId == null || appId.isEmpty()) {
      promise.reject(TAG, "appId is required");
      return;
    }

    DyADCore.tt_appid = appId;
    DyADCore.debug = options.hasKey("debug") && options.getBoolean("debug");
    DyADCore.appName = options.hasKey("appName")
      ? options.getString("appName")
      : DyADCore.appName;
    DyADCore.initSdk(reactAppContext, appId, DyADCore.debug);

    if (TTAdSdk.isSdkReady()) {
      promise.resolve(true);
      return;
    }

    TTAdSdk.start(new TTAdSdk.Callback() {
      @Override
      public void success() {
        promise.resolve(true);
      }

      @Override
      public void fail(int code, String msg) {
        promise.reject(TAG, "SDK init failed: " + code + ", " + msg);
      }
    });
  }

  @ReactMethod
  public void preloadAd(ReadableMap request, Promise promise) {
    if (DyADCore.TTAdSdk == null) {
      promise.reject(TAG, "TTAdSdk not initialized");
      return;
    }

    String requestId = request.getString("requestId");
    String format = request.getString("format");
    ReadableArray slotIds = request.getArray("slotIds");
    String slotId = slotIds != null && slotIds.size() > 0 ? slotIds.getString(0) : null;
    ReadableMap size = request.hasKey("size") ? request.getMap("size") : null;
    int width = size != null && size.hasKey("width") ? size.getInt("width") : 0;
    int height = size != null && size.hasKey("height") ? size.getInt("height") : 0;

    if (slotId == null || slotId.isEmpty()) {
      promise.reject(TAG, "slotIds is required");
      return;
    }

    if ("feed".equals(format) || "banner".equals(format)) {
      preloadExpressAd(requestId, format, slotId, width, height, promise);
      return;
    }

    if ("splash".equals(format)) {
      preloadSplashAdV2(requestId, slotId, width, height, promise);
      return;
    }

    promise.reject(TAG, "unsupported format: " + format);
  }

  private void preloadExpressAd(
    String requestId,
    String format,
    String slotId,
    int width,
    int height,
    Promise promise
  ) {
    AdSlot.Builder builder = new AdSlot.Builder()
      .setCodeId(slotId)
      .setSupportDeepLink(true)
      .setAdCount(1)
      .setExpressViewAcceptedSize(width > 0 ? width : 320, "banner".equals(format) ? Math.max(height, 50) : 0);

    TTAdNative.NativeExpressAdListener listener = new TTAdNative.NativeExpressAdListener() {
      @Override
      public void onError(int code, String message) {
        promise.reject(String.valueOf(code), message);
      }

      @Override
      public void onNativeExpressAdLoad(List<TTNativeExpressAd> ads) {
        if (ads == null || ads.isEmpty()) {
          promise.reject(TAG, "no ad content");
          return;
        }
        AdResourcePool.Entry entry = AdResourcePool.put(
          requestId,
          format,
          slotId,
          width,
          height,
          ads.get(0)
        );
        promise.resolve(toTokenMap(entry));
      }
    };

    if ("banner".equals(format)) {
      DyADCore.TTAdSdk.loadBannerExpressAd(builder.build(), listener);
    } else {
      DyADCore.TTAdSdk.loadNativeExpressAd(builder.build(), listener);
    }
  }

  private void preloadSplashAdV2(
    String requestId,
    String slotId,
    int width,
    int height,
    Promise promise
  ) {
    AdSlot adSlot = new AdSlot.Builder()
      .setCodeId(slotId)
      .setSupportDeepLink(true)
      .setExpressViewAcceptedSize(width > 0 ? width : 320, height > 0 ? height : 480)
      .build();
    DyADCore.TTAdSdk.loadSplashAd(
      adSlot,
      new TTAdNative.CSJSplashAdListener() {
        @Override
        public void onSplashLoadSuccess(CSJSplashAd ad) {}

        @Override
        public void onSplashLoadFail(CSJAdError error) {
          promise.reject(TAG, error != null ? error.getMsg() : "splash load failed");
        }

        @Override
        public void onSplashRenderSuccess(CSJSplashAd ad) {
          AdResourcePool.Entry entry = AdResourcePool.put(
            requestId,
            "splash",
            slotId,
            width,
            height,
            ad
          );
          promise.resolve(toTokenMap(entry));
        }

        @Override
        public void onSplashRenderFail(CSJSplashAd ad, CSJAdError error) {
          promise.reject(TAG, error != null ? error.getMsg() : "splash render failed");
        }
      },
      5000
    );
  }

  @ReactMethod
  public void showSplashAdV2(ReadableMap params, Promise promise) {
    ReadableMap request = params.getMap("request");
    if (request == null) {
      promise.reject(TAG, "request is required");
      return;
    }
    String requestId = request.getString("requestId");
    ReadableArray slotIds = request.getArray("slotIds");
    String slotId = slotIds != null && slotIds.size() > 0 ? slotIds.getString(0) : null;
    String token = null;
    if (params.hasKey("preloadToken")) {
      ReadableMap preloadToken = params.getMap("preloadToken");
      token = preloadToken != null ? preloadToken.getString("token") : null;
    }
    int timeoutMs = params.hasKey("timeoutMs") ? params.getInt("timeoutMs") : 8000;

    if (slotId == null || slotId.isEmpty()) {
      promise.reject(TAG, "slotIds is required");
      return;
    }
    if (getCurrentActivity() == null) {
      promise.reject(TAG, "Activity not ready");
      return;
    }

    splashPromises.put(requestId, promise);
    Intent intent = new Intent(getCurrentActivity(), SplashActivity.class);
    intent.putExtra("requestId", requestId);
    intent.putExtra("codeid", slotId);
    intent.putExtra("preloadToken", token);
    intent.putExtra("timeoutMs", timeoutMs);
    getCurrentActivity().startActivity(intent);
    getCurrentActivity().overridePendingTransition(0, 0);
  }

  public static void emitV2Event(WritableMap event) {
    if (reactAppContext != null && reactAppContext.hasActiveCatalystInstance()) {
      reactAppContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit("BrayantAd-onEvent", event);
    }
  }

  @ReactMethod
  public void addListener(String eventName) {}

  @ReactMethod
  public void removeListeners(double count) {}

  public static void resolveSplashV2(
    String requestId,
    String slotId,
    String status,
    long elapsedMs,
    String errorMessage
  ) {
    Promise promise = splashPromises.remove(requestId);
    if (promise == null) {
      return;
    }
    WritableMap result = Arguments.createMap();
    result.putString("requestId", requestId);
    result.putString("slotId", slotId);
    result.putString("status", status);
    result.putDouble("elapsedMs", elapsedMs);
    if (errorMessage != null) {
      WritableMap error = Arguments.createMap();
      error.putString("code", "SPLASH_ERROR");
      error.putString("message", errorMessage);
      result.putMap("error", error);
    }
    promise.resolve(result);
  }

  private static WritableMap toTokenMap(AdResourcePool.Entry entry) {
    WritableMap result = Arguments.createMap();
    result.putString("token", entry.token);
    result.putString("requestId", entry.requestId);
    result.putString("format", entry.format);
    result.putString("slotId", entry.slotId);
    result.putDouble("expiresAt", entry.expiresAt);
    return result;
  }


  /**
   * 方便从RN主动预加载第一个广告，避免用户第一个签到的信息流广告加载+图片显示感觉很慢
   * （需要注意在展示弹层前才预加载）
   */
  @ReactMethod
  public void loadFeedAd(ReadableMap options, final Promise promise) {
    String codeId = options.getString("codeid");
    if (codeId == null || codeId.isEmpty()) {
      promise.reject(TAG, "codeid is required");
      return;
    }
    float width = parseAdWidth(options);
    DyADCore.feedPromise = promise;
//    if (DyADCore.feed_provider.equals("腾讯")) {
//      //FIXME ...
//      return;
//    }
//    if (DyADCore.feed_provider.equals("百度")) {
//      //百度的是横幅banner，不需要预加载
//      return;
//    }
    loadTTFeedAd(codeId, width);
  }

  /**
   * 预加载信息流广告（FeedAd）
   * 在组件渲染前调用，提前加载广告数据，减少白屏时间
   * 与 loadFeedAd 的区别：此方法不依赖 Promise 回调，静默预加载
   */
  @ReactMethod
  public void preloadFeedAd(ReadableMap options, final Promise promise) {
    String codeId = options.getString("codeid");
    if (codeId == null || codeId.isEmpty()) {
      promise.reject(TAG, "codeid is required");
      return;
    }

    float width = parseAdWidth(options);

    // 检查 SDK 是否初始化
    if (DyADCore.TTAdSdk == null) {
      promise.reject(TAG, "TTAdSdk not initialized");
      return;
    }

    // 如果已经有缓存的广告，直接返回成功
    if (DyADCore.hasValidFeedAdCache(codeId)) {
      promise.resolve(true);
      return;
    }

    // 创建广告请求参数
    float expressViewWidth = width > 0 ? width : 280;
    float expressViewHeight = 0; // 自动高度

    AdSlot adSlot = new AdSlot.Builder()
      .setCodeId(codeId)
      .setSupportDeepLink(true)
      .setAdCount(1)
      .setExpressViewAcceptedSize(expressViewWidth, expressViewHeight)
      .setImageAcceptedSize(640, 320)
      .setNativeAdType(AdSlot.TYPE_INTERACTION_AD)
      .build();

    // 请求广告
    DyADCore.TTAdSdk.loadNativeExpressAd(
      adSlot,
      new TTAdNative.NativeExpressAdListener() {
        @Override
        public void onError(int code, String message) {
          Log.d(TAG, "preloadFeedAd error: " + message);
          promise.reject(TAG, "preload feed ad error: " + message);
        }

        @Override
        public void onNativeExpressAdLoad(List<TTNativeExpressAd> ads) {
          Log.d(TAG, "preloadFeedAd success");
          if (ads == null || ads.isEmpty()) {
            promise.reject(TAG, "preload feed ad: no ad content");
            return;
          }
          // 缓存加载成功的广告
          DyADCore.cacheFeedAd(codeId, ads.get(0));
          promise.resolve(true);
        }
      }
    );
  }

  /**
   * 加载穿山甲的信息流广告
   *
   * @param codeId
   * @param width
   */
  private static void loadTTFeedAd(String codeId, float width) {
    if (DyADCore.TTAdSdk == null) {
      Log.e(TAG, "TTAdSdk 还没初始化");
      return;
    }

    // step4:创建广告请求参数AdSlot,具体参数含义参考文档
    // 默认宽度，兼容大部分弹层的宽度即可
    float expressViewWidth = width > 0 ? width : 280;
    float expressViewHeight = 0; // 自动高度

    AdSlot adSlot = new AdSlot.Builder()
      .setCodeId(codeId) // 广告位id
      .setSupportDeepLink(true)
      .setAdCount(1) // 请求广告数量为1到3条
      .setExpressViewAcceptedSize(expressViewWidth, expressViewHeight) // 期望模板广告view的size,单位dp,高度0自适应
      .setImageAcceptedSize(640, 320)
      .setNativeAdType(AdSlot.TYPE_INTERACTION_AD) // 坑啊，不设置这个，feed广告native出不来，一直差量无效，文档太烂
      .build();

    // step5:请求广告，对请求回调的广告作渲染处理
    DyADCore.TTAdSdk.loadNativeExpressAd(
      adSlot,
      new TTAdNative.NativeExpressAdListener() {
        @Override
        public void onError(int code, String message) {
          Log.d(TAG, message);
          if (DyADCore.feedPromise != null) {
            DyADCore.feedPromise.reject("101", "feed ad error" + message);
            DyADCore.feedPromise = null;
          }
        }

        @Override
        public void onNativeExpressAdLoad(List<TTNativeExpressAd> ads) {
          Log.d(TAG, "onNativeExpressAdLoad: FeedAd !!!");
          if (ads == null || ads.isEmpty()) {
            if (DyADCore.feedPromise != null) {
              DyADCore.feedPromise.reject("101", "feed ad empty");
              DyADCore.feedPromise = null;
            }
            return;
          }
          // 缓存加载成功的信息流广告
          DyADCore.cacheFeedAd(codeId, ads.get(0));
          if (DyADCore.feedPromise != null) {
            DyADCore.feedPromise.resolve(true);
            DyADCore.feedPromise = null;
          }
        }
      }
    );
  }

  private static float parseAdWidth(ReadableMap options) {
    if (!options.hasKey("adWidth")) {
      return 0;
    }
    ReadableType type = options.getType("adWidth");
    if (type == ReadableType.Number) {
      return (float) options.getDouble("adWidth");
    }
    if (type == ReadableType.String) {
      try {
        String width = options.getString("adWidth");
        if (width != null) {
          return Float.parseFloat(width);
        }
      } catch (NumberFormatException exception) {
        Log.w(TAG, "Invalid adWidth value", exception);
      }
    }
    return 0;
  }

  /**
   * 主动看激励视频时，才检查这个权限
   */
  @ReactMethod
  public void requestPermission() {
    // step3:(可选，强烈建议在合适的时机调用):申请部分权限，如read_phone_state,防止获取不了imei时候，下载类广告没有填充的问题。
    DyADCore.ttAdManager.requestPermissionIfNecessary(reactAppContext);
  }
}
