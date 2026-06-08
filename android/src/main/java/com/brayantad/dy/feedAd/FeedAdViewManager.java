package com.brayantad.dy.feedAd;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReactContext;

import com.brayantad.dy.feedAd.view.FeedAdView;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.Map;

public class FeedAdViewManager extends ViewGroupManager<FeedAdView> {
  public static final String TAG = "FeedAdViewManager";
  private ReactContext mContext;

  @NonNull
  @Override
  public String getName() {
    return TAG;
  }

  @NonNull
  @Override
  protected FeedAdView createViewInstance(@NonNull ThemedReactContext themedReactContext) {
    return new FeedAdView(themedReactContext);
  }

  @Override
  public void removeAllViews(FeedAdView parent) {
    super.removeAllViews(parent);
  }

  @Override
  public void onDropViewInstance(@NonNull FeedAdView view) {
    // 组件卸载时释放广告资源，防止内存泄漏
    view.destroy();
    super.onDropViewInstance(view);
  }

  @Override
  public boolean needsCustomLayoutForChildren() {
    return true;
  }

  @ReactProp(name = "codeid")
  public void setCodeId(FeedAdView view, @Nullable String codeid) {
    view.setCodeId(codeid);
  }

  @ReactProp(name = "requestId")
  public void setRequestId(FeedAdView view, @Nullable String requestId) {
    view.setRequestId(requestId);
  }

  @ReactProp(name = "preloadToken")
  public void setPreloadToken(FeedAdView view, @Nullable String preloadToken) {
    view.setPreloadToken(preloadToken);
  }

  @ReactProp(name = "adWidth")
  public void setAdWidth(FeedAdView view, int adWidth) {
    view.setWidth(adWidth);
  }

  @ReactProp(name = "visible", defaultBoolean = true)
  public void setVisible(FeedAdView view, boolean visible) {
    view.setVisible(visible);
  }

  @Override
  public Map getExportedCustomBubblingEventTypeConstants() {
    return MapBuilder
      .builder()
      .put("onAdClick", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdClick")))
      .put("onAdError", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdError")))
      .put("onAdClose", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdClose")))
      .put("onAdLayout", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdLayout")))
      .put("onAdEvent", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdEvent")))
      .build();
  }
}
