package com.brayantad.dy.feedAd.view;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.RelativeLayout;

/** 广告模板按内容测高，不能被 React Native 的占位高度反向限制。 */
public class FeedAdContentLayout extends RelativeLayout {
  public FeedAdContentLayout(Context context) {
    super(context);
  }

  public FeedAdContentLayout(Context context, AttributeSet attrs) {
    super(context, attrs);
  }

  @Override
  protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    super.onMeasure(widthMeasureSpec, MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED));
  }
}
