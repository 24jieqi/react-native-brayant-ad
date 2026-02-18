package com.brayantad.dy.splash.activity;

import static com.bytedance.sdk.openadsdk.TTAdLoadType.LOAD;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.os.Message;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.widget.FrameLayout;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.brayantad.AdManager;
import com.brayantad.R;
import com.brayantad.dy.DyADCore;
import com.brayantad.dy.WeakHandler;
import com.brayantad.utils.TToast;
import com.bytedance.sdk.openadsdk.AdSlot;
import com.bytedance.sdk.openadsdk.CSJAdError;
import com.bytedance.sdk.openadsdk.TTAdNative;
import com.bytedance.sdk.openadsdk.TTAdSdk;
import com.bytedance.sdk.openadsdk.CSJSplashAd;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;


@SuppressLint("CustomSplashScreen")
public class SplashActivity extends AppCompatActivity implements WeakHandler.IHandler {
  // 开屏广告加载超时时间，弱网下适度放宽可提升填充率
  private static final int AD_TIME_OUT = 5000;
  private static final int MSG_GO_MAIN = 1;
  static String TAG = "SplashAd";
  // 开屏广告加载发生超时但是SDK没有及时回调结果的时候，做的一层保护。
  private final WeakHandler mHandler = new WeakHandler(this);
  private TTAdNative mTTAdNative;
  private FrameLayout mSplashContainer;
  // 是否强制跳转到主页面
  private boolean mForceGoMain;
  // 开屏广告是否已经加载
  private boolean mHasLoaded;

  private String code_id;

  // 注册监听方法
  private static void sendEvent(String eventName, WritableMap params) {
    AdManager
      .reactAppContext.getJSModule(
        DeviceEventManagerModule.RCTDeviceEventEmitter.class
      )
      .emit(eventName, params);
  }

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_splash);

    // 读取 code id
    Bundle extras = getIntent().getExtras();
    code_id = extras != null ? extras.getString("codeid") : null;

    // 初始化广告 SDK
    mTTAdNative = DyADCore.TTAdSdk;

    // 在合适的时机申请权限，如read_phone_state,防止获取不了 imei 时候，下载类广告没有填充的问题
    // 在开屏时候申请不太合适，因为该页面倒计时结束或者请求超时会跳转，在该页面申请权限，体验不好
    // TTAdManagerHolder.getInstance(this).requestPermissionIfNecessary(this);

    // 初始化自定义广告 View
    initView();

    // 绑定广告控制 Activity
    DyADCore.hookActivity(this);

    boolean sdkReady = TTAdSdk.isSdkReady();
    boolean hasPreloadedAd = DyADCore.splashAd != null && sdkReady && isPreloadValid();

    if (hasPreloadedAd) {
      // 直接展示预加载的开屏广告，无需等待加载
      Log.d(TAG, "使用预加载的开屏广告，直接展示");
      showSplashAd();
    } else {
      // 没有预加载或已过期，需要实时加载
      Log.d(TAG, "没有预加载广告，开始实时加载");

      // 定时，AD_TIME_OUT时间到时执行，如果开屏广告没有加载则跳转到主页面
      mHandler.sendEmptyMessageDelayed(MSG_GO_MAIN, AD_TIME_OUT);

      // 加载并显示开屏广告
      loadSplashAd(
        this,
        code_id,
        this::showSplashAd,
        () -> {
          mHasLoaded = true;
          goToMainActivity();
        }
      );
    }
  }

  /**
   * 检查预加载的广告是否仍然有效（5分钟有效期）
   */
  private boolean isPreloadValid() {
    if (DyADCore.splashPreloadTime == 0) return false;
    long elapsed = System.currentTimeMillis() - DyADCore.splashPreloadTime;
    return elapsed < DyADCore.SPLASH_PRELOAD_VALID_DURATION;
  }

  // 初始化开屏广告 View
  private void initView() {
    // 初始化广告渲染组件
    mSplashContainer = this.findViewById(R.id.splash_container);
    // 设置软件底部 icon，title
//    try {
//      ActivityInfo appInfo = getPackageManager()
//        .getActivityInfo(this.getComponentName(), PackageManager.GET_META_DATA);
//
//      RoundedCorners roundedCorners = new RoundedCorners(20);
//      // 通过RequestOptions扩展功能,override:采样率,因为ImageView就这么大,可以压缩图片,降低内存消耗
//      RequestOptions options = RequestOptions
//        .bitmapTransform(roundedCorners)
//        .override(300, 300);
//      ImageView splashIcon = findViewById(R.id.splash_icon);
//      Glide
//        .with(this)
//        .load(appInfo.loadIcon(getPackageManager()))
//        .apply(options)
//        .into(splashIcon);
//      // 设置 appIcon
//
//      Bundle bundle = appInfo.metaData;
//
//      if (bundle != null) {
//        String splashTitle = bundle.getString("splash_title");
//        // 获取标题
//
//        int splashTitleColor = bundle.getInt("splash_title_color");
//        // 获取标题颜色
//
//        TextView splashName = findViewById(R.id.splash_name);
//        if (splashTitle != null) {
//          splashName.setText(splashTitle);
//        }
//        if (splashTitleColor != 0) {
//          splashName.setTextColor(splashTitleColor);
//        }
//      }
//    } catch (PackageManager.NameNotFoundException e) {
//      e.printStackTrace();
//    }
  }

  // 加载开屏广告方法
  public static void loadSplashAd(
    AppCompatActivity activity,
    String code_id,
    Runnable callback,
    Runnable goback
  ) {
    TTAdNative mTTAdNative;

    if (DyADCore.TTAdSdk == null) {
      // 广告 SDK 未初始化
      WritableMap params = Arguments.createMap();
      params.putString("onAdError", "广告 sdk init 异常");
      sendEvent(TAG + "-onAdError", params);
      return;
    } else {
      mTTAdNative = DyADCore.TTAdSdk;
    }

    if (code_id == null || code_id.isEmpty()) {
      WritableMap params = Arguments.createMap();
      params.putString("onAdError", "广告位ID为空");
      sendEvent(TAG + "-onAdError", params);
      goback.run();
      return;
    }

    // 创建开屏广告请求参数 AdSlot ,具体参数含义参考文档
    // ①模板渲染的开屏请求方法需设置setExpressViewAcceptedSize参数 单位dp。非模板渲染开屏请求方法需设置setImageAcceptedSize参数 单位px 。切记不可使用错误
    int[] expressSizeDp = resolveExpressViewSizeDp(activity);
    AdSlot adSlot = new AdSlot.Builder()
      .setCodeId(code_id)
      .setSupportDeepLink(true)
      .setExpressViewAcceptedSize(expressSizeDp[0], expressSizeDp[1])
      .setAdLoadType(LOAD)
      .build();

    // 请求广告，调用开屏广告异步请求接口，对请求回调的广告作渲染处理

    mTTAdNative.loadSplashAd(
      adSlot,
      new TTAdNative.CSJSplashAdListener() {

        @Override
        public void onSplashLoadSuccess(CSJSplashAd csjSplashAd) {
          //5700及以上新增，开屏素材加载成功

        }

        @Override
        public void onSplashLoadFail(CSJAdError csjAdError) {
          // 广告渲染失败
          Log.d(TAG, "开屏广告加载失败:" + csjAdError);
          DyADCore.splashAd = null;
          // 回调监听方法
          WritableMap params = Arguments.createMap();
          String errorMessage = "广告渲染加载:" + csjAdError;
          params.putString("onSplashLoadFail", errorMessage);
          params.putString("onAdError", errorMessage);
          sendEvent(TAG + "-onSplashLoadFail", params);
          sendEvent(TAG + "-onAdError", params);

          // 关闭开屏广告
          goback.run();
        }

        @Override
        public void onSplashRenderSuccess(CSJSplashAd csjSplashAd) {
          // 开屏广告加载成功，调用显示开屏广告
          DyADCore.splashAd = csjSplashAd;
          callback.run();
        }

        @Override
        public void onSplashRenderFail(CSJSplashAd csjSplashAd, CSJAdError csjAdError) {
          // 广告渲染失败
          Log.d(TAG, "开屏广告渲染失败:" + csjAdError);
          DyADCore.splashAd = null;
          // showToast(message + " - " + code_id);

          // 回调监听方法
          WritableMap params = Arguments.createMap();
          params.putString("onAdError", "广告渲染失败:" + csjAdError);
          sendEvent(TAG + "-onAdError", params);

          // 关闭开屏广告
          goback.run();
        }
      },
      AD_TIME_OUT
    );
  }

  private static int[] resolveExpressViewSizeDp(AppCompatActivity activity) {
    DisplayMetrics metrics = activity.getResources().getDisplayMetrics();
    int widthDp = Math.round(metrics.widthPixels / metrics.density);
    int heightDp = Math.round(metrics.heightPixels / metrics.density);

    // 按屏幕尺寸动态设置模板大小，避免固定超大尺寸导致低填充
    widthDp = Math.max(widthDp, 320);
    heightDp = Math.max(heightDp, 480);

    return new int[]{widthDp, heightDp};
  }

  private void showSplashAd() {
    CSJSplashAd ad = DyADCore.splashAd;
    mHasLoaded = true;
    mHandler.removeCallbacksAndMessages(null);
    if (ad == null) {
      // 回调监听方法
      WritableMap params = Arguments.createMap();
      params.putString("onAdError", "未拉取到开屏广告");
      sendEvent(TAG + "-onAdError", params);

      // 未知错误获取到的广告对象为空，关闭广告
      goToMainActivity();
      return;
    }

    // 清空加载成功的广告对象
    DyADCore.splashAd = null;

    // 获取SplashView
    View view = ad.getSplashView();
    mSplashContainer.removeAllViews();

    // 把SplashView 添加到ViewGroup中,注意开屏广告view：width >=70%屏幕宽；height >=50%屏幕宽
    mSplashContainer.addView(view);

    // 设置不开启开屏广告倒计时功能以及不显示跳过按钮,如果这么设置，您需要自定义倒计时逻辑
    // ad.setNotAllowSdkCountdown();

    // 设置SplashView的交互监听器

    ad.setSplashAdListener(

      new CSJSplashAd.SplashAdListener() {

        @Override
        public void onSplashAdShow(CSJSplashAd csjSplashAd) {
          Log.d(TAG, "onAdShow");
          WritableMap params = Arguments.createMap();
          params.putBoolean("onAdShow", true);
          sendEvent(TAG + "-onAdShow", params);
        }

        @Override
        public void onSplashAdClick(CSJSplashAd csjSplashAd) {
          Log.d(TAG, "onAdClick");
          WritableMap params = Arguments.createMap();
          params.putBoolean("onAdClick", true);
          sendEvent(TAG + "-onAdClick", params);

          // showToast("开屏广告点击");
          goToMainActivity();
        }

        @Override
        public void onSplashAdClose(CSJSplashAd csjSplashAd,  int closeType) {
          Log.d(TAG, "onAdSkip");
          WritableMap params = Arguments.createMap();
          params.putBoolean("onAdClose", true);
          sendEvent(TAG + "-onAdClose", params);

          // showToast("开屏广告跳过");
          goToMainActivity();
        }
      }
    );
  }

  // 关闭开屏广告方法
  private void goToMainActivity() {
    if (DyADCore.rewardActivity == null) {
      // 开屏广告控制活动未绑定
      return;
    }
    if (mSplashContainer != null) {
      mSplashContainer.removeAllViews();
    }
    DyADCore.rewardActivity.overridePendingTransition(0, 0); // 不要过渡动画
    DyADCore.rewardActivity.finish();
  }

  private void showToast(String msg) {
    TToast.show(this, "splash:" + msg);
  }

  @Override
  public void handleMsg(Message msg) {
    if (msg.what == MSG_GO_MAIN) {
      if (!mHasLoaded) {
        showToast("加载超时");
        goToMainActivity();
      }
    }
  }

  @Override
  public void finish() {
    super.finish();
    if (DyADCore.splashAd_anim_in != -1) {
      // 实现广告关闭跳转 Activity 动画设置
      overridePendingTransition(
        DyADCore.splashAd_anim_in,
        DyADCore.splashAd_anim_out
      );
    }
  }
}
