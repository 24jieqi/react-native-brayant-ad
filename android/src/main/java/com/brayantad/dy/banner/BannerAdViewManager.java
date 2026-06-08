package com.brayantad.dy.banner;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.brayantad.dy.banner.view.BannerAdView;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.Map;

public class BannerAdViewManager extends ViewGroupManager<BannerAdView> {
  public static final String TAG = "BannerAdViewManager";

  @NonNull
  @Override
  public String getName() {
    return TAG;
  }

  @NonNull
  @Override
  protected BannerAdView createViewInstance(@NonNull ThemedReactContext themedReactContext) {
    return new BannerAdView(themedReactContext);
  }

  @Override
  public void removeAllViews(BannerAdView parent) {
    super.removeAllViews(parent);
  }

  @Override
  public void onDropViewInstance(@NonNull BannerAdView view) {
    view.destroy();
    super.onDropViewInstance(view);
  }

  @Override
  public boolean needsCustomLayoutForChildren() {
    return true;
  }

  @ReactProp(name = "codeid")
  public void setCodeId(BannerAdView view, @Nullable String codeid) {
    view.setCodeId(codeid);
  }

  @ReactProp(name = "requestId")
  public void setRequestId(BannerAdView view, @Nullable String requestId) {
    view.setRequestId(requestId);
  }

  @ReactProp(name = "preloadToken")
  public void setPreloadToken(BannerAdView view, @Nullable String preloadToken) {
    view.setPreloadToken(preloadToken);
  }

  @ReactProp(name = "adWidth")
  public void setAdWidth(BannerAdView view, int adWidth) {
    view.setWidth(adWidth);
  }

  @ReactProp(name = "adHeight")
  public void setAdHeight(BannerAdView view, int adHeight) {
    view.setHeight(adHeight);
  }

  @ReactProp(name = "visible")
  public void setVisible(BannerAdView view, boolean visible) {
    view.setVisibility(visible);
  }

  @Override
  public Map getExportedCustomBubblingEventTypeConstants() {
    return MapBuilder
      .builder()
      .put("onAdClick", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdClick")))
      .put("onAdError", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdError")))
      .put("onAdShow", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdShow")))
      .put("onAdRenderSuccess", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdRenderSuccess")))
      .put("onAdDismiss", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdDismiss")))
      .put("onAdDislike", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdDislike")))
      .put("onAdEvent", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAdEvent")))
      .build();
  }
}
