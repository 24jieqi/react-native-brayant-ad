const { readFileSync } = require('fs');
const path = require('path');

describe('Android Banner 原生渲染契约', () => {
  it('预加载缓存广告必须通过 render 回调确认展示成功', () => {
    const source = readFileSync(
      path.resolve(
        'android/src/main/java/com/brayantad/dy/banner/view/BannerAdView.java'
      ),
      'utf8'
    );
    const cachedBranch = source.slice(
      source.indexOf('if (cachedAd != null) {'),
      source.indexOf('// 没有缓存，正常加载')
    );

    expect(cachedBranch).toContain('showBannerAd(mBannerAd);');
    expect(cachedBranch).not.toContain('getExpressAdView() != null');
    expect(cachedBranch).not.toContain('mHasRenderedAd = true');
  });
});
