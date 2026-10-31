package com.brayantad.dy.feedAd.view;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import java.util.Arrays;
import java.util.Collection;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.ParameterizedRobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

/** 验证广告真实高度不受 RN 初始占位高度限制，同时保留请求宽度约束。 */
@RunWith(ParameterizedRobolectricTestRunner.class)
@Config(sdk = 28, manifest = Config.NONE)
public class FeedAdContentLayoutTest {
  private final int width;
  private final int parentHeightMode;
  private final int parentHeight;

  @ParameterizedRobolectricTestRunner.Parameters(name = "宽度={0}, 父高度模式={1}, 父高度={2}")
  public static Collection<Object[]> parameters() {
    return Arrays.asList(new Object[][] {
      {279, View.MeasureSpec.EXACTLY, 100},
      {271, View.MeasureSpec.EXACTLY, 100},
      {279, View.MeasureSpec.AT_MOST, 120},
      {271, View.MeasureSpec.AT_MOST, 120}
    });
  }

  public FeedAdContentLayoutTest(int width, int parentHeightMode, int parentHeight) {
    this.width = width;
    this.parentHeightMode = parentHeightMode;
    this.parentHeight = parentHeight;
  }

  @Test
  public void standardRelativeLayoutClipsMaterialToPlaceholderHeight() {
    RelativeLayout layout = new RelativeLayout(context());
    MaterialView material = addMaterial(layout, 386);
    measureAndLayout(layout, View.MeasureSpec.EXACTLY);
    // 旧容器将占位高度传给素材：素材和容器都只得到 100/120 像素。
    assertEquals(parentHeight, layout.getMeasuredHeight());
    assertEquals(parentHeight, material.getMeasuredHeight());
    assertTrue(material.getMeasuredHeight() < material.desiredHeight);
  }

  @Test
  public void measuresFullMaterialDespitePlaceholderHeight() {
    FeedAdContentLayout layout = new FeedAdContentLayout(context());
    MaterialView material = addMaterial(layout, 386);
    measureAndLayout(layout, View.MeasureSpec.EXACTLY);
    assertFullHeight(layout, material, 386);
    assertEquals(width, layout.getMeasuredWidth());
    assertEquals(width, material.getMeasuredWidth());
    assertEquals(View.MeasureSpec.UNSPECIFIED, material.lastHeightMode);
  }

  @Test
  public void remeasuresAsyncGrowthAndRealShrinkage() {
    FeedAdContentLayout layout = new FeedAdContentLayout(context());
    MaterialView material = addMaterial(layout, 100);
    measureAndLayout(layout, View.MeasureSpec.EXACTLY);
    assertFullHeight(layout, material, 100);
    // 模拟异步图片到达及素材替换，不能只保留历史最大高度。
    material.setDesiredHeight(386);
    measureAndLayout(layout, View.MeasureSpec.EXACTLY);
    assertFullHeight(layout, material, 386);
    material.setDesiredHeight(160);
    measureAndLayout(layout, View.MeasureSpec.EXACTLY);
    assertFullHeight(layout, material, 160);
    assertEquals(width, layout.getMeasuredWidth());
    assertEquals(width, material.getMeasuredWidth());
  }

  @Test
  public void respectsAtMostWidthWhileMeasuringFullHeight() {
    FeedAdContentLayout layout = new FeedAdContentLayout(context());
    MaterialView material = addMaterial(layout, 386);
    measureAndLayout(layout, View.MeasureSpec.AT_MOST);
    assertFullHeight(layout, material, 386);
    assertEquals(width, layout.getMeasuredWidth());
    assertEquals(width, material.getMeasuredWidth());
    // RelativeLayout 可将 MATCH_PARENT 子视图重测为 EXACTLY；结果必须受父宽度约束。
    assertTrue(material.getRight() <= width);
  }

  private Context context() {
    return RuntimeEnvironment.getApplication();
  }

  private MaterialView addMaterial(RelativeLayout layout, int desiredHeight) {
    MaterialView material = new MaterialView(context(), desiredHeight);
    layout.addView(material, new RelativeLayout.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
    return material;
  }

  private void measureAndLayout(RelativeLayout layout, int widthMode) {
    layout.measure(View.MeasureSpec.makeMeasureSpec(width, widthMode),
      View.MeasureSpec.makeMeasureSpec(parentHeight, parentHeightMode));
    layout.layout(0, 0, layout.getMeasuredWidth(), layout.getMeasuredHeight());
  }

  private void assertFullHeight(RelativeLayout layout, MaterialView material, int height) {
    assertEquals(height, layout.getMeasuredHeight());
    assertEquals(height, material.getMeasuredHeight());
    assertEquals(height, material.getBottom());
    assertEquals(height, layout.getBottom());
  }

  /** 遵守父测量规格的素材，模拟广告图片异步完成后修改期望高度。 */
  private static final class MaterialView extends View {
    private int desiredHeight;
    private int lastHeightMode;

    MaterialView(Context context, int desiredHeight) {
      super(context);
      this.desiredHeight = desiredHeight;
    }

    void setDesiredHeight(int height) {
      desiredHeight = height;
      requestLayout();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
      lastHeightMode = MeasureSpec.getMode(heightMeasureSpec);
      setMeasuredDimension(resolveSize(1000, widthMeasureSpec),
        resolveSize(desiredHeight, heightMeasureSpec));
    }
  }
}
