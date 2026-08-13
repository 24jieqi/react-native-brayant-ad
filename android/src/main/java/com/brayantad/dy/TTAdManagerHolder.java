package com.brayantad.dy;

import android.content.Context;
import android.util.Log;

import com.bytedance.sdk.openadsdk.TTAdConfig;
import com.bytedance.sdk.openadsdk.TTAdConstant;
import com.bytedance.sdk.openadsdk.TTAdManager;
import com.bytedance.sdk.openadsdk.TTCustomController;
import com.bytedance.sdk.openadsdk.TTAdSdk;

import java.util.HashMap;
import java.util.Map;

/**
 * 单例来保存TTAdManager实例，在需要初始化sdk的时候调用
 */
public class TTAdManagerHolder {
  public static boolean sInit;
  public static Context mContext;

  public static TTAdManager get() {
    if (!sInit) {
      throw new RuntimeException("TTAdSdk is not init, please check.");
    }
    return TTAdSdk.getAdManager();
  }

  public static void init(Context context, String appid, Boolean debug) {
    mContext = context;
    doInit(context, appid, debug);
  }

  // 接入网盟广告sdk的初始化操作，详情见接入文档和穿山甲平台说明
  private static void doInit(
    final Context context,
    final String appid,
    final Boolean debug
  ) {
    if (!sInit) {
      sInit = TTAdSdk.init(context, buildConfig(context, appid, debug));
    }
  }

  private static TTAdConfig buildConfig(
    Context context,
    String appid,
    Boolean debug
  ) {
    return new TTAdConfig.Builder()
      .appId(appid)
      .appName(DyADCore.appName)
      .titleBarTheme(TTAdConstant.TITLE_BAR_THEME_DARK)
      .allowShowNotify(true) //是否允许sdk展示通知栏提示
      .debug(debug) //测试阶段打开，可以通过日志排查问题，上线时去除该调用
      .directDownloadNetworkType() //允许直接下载的网络状态集合
      .supportMultiProcess(false)
      .customController(buildPrivacyController())
      .build();
  }

  private static TTCustomController buildPrivacyController() {
    return new TTCustomController() {
      @Override
      public boolean isCanUseLocation() {
        return false;
      }

      @Override
      public boolean alist() {
        return false;
      }

      @Override
      public boolean isCanUsePhoneState() {
        return false;
      }

      @Override
      public String getDevImei() {
        return "";
      }

      @Override
      public boolean isCanUseWifiState() {
        return false;
      }

      @Override
      public String getMacAddress() {
        return "";
      }

      @Override
      public boolean isCanUseWriteExternal() {
        return false;
      }

      @Override
      public String getDevOaid() {
        return "";
      }

      @Override
      public boolean isCanUseAndroidId() {
        return false;
      }

      @Override
      public String getAndroidId() {
        return "";
      }

      @Override
      public boolean isCanUsePermissionRecordAudio() {
        return false;
      }

      @Override
      public boolean isCanUseMessage() {
        return false;
      }

      @Override
      public Map<String, Object> userPrivacyConfig() {
        Map<String, Object> config = new HashMap<>();
        config.put("motion_info", 0);
        return config;
      }
    };
  }
}
