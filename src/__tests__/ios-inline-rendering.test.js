const fs = require('fs');
const path = require('path');

const readIOSSource = (fileName) =>
  fs.readFileSync(
    path.resolve(__dirname, `../../ios/PangleAdModule/${fileName}`),
    'utf8'
  );

describe('iOS 广告线程与渲染契约', () => {
  it('PangleAdModule 的 RN 方法固定在主线程执行', () => {
    const source = readIOSSource('PangleAdModule.m');

    expect(source).toMatch(
      /- \(dispatch_queue_t\)methodQueue\s*\{\s*return dispatch_get_main_queue\(\);\s*\}/
    );
  });

  it('开屏以 didShow 为主信号，并对 presented 和终态做单次保护', () => {
    const source = readIOSSource('SplashAd.m');

    expect(source).toMatch(/- \(void\)splashAdDidShow:/);
    expect(source).toMatch(/- \(void\)splashAdDidShowFailed:/);
    expect(source).toMatch(/\[self notifyPresentedIfNeeded\];/);
    expect(source).toMatch(/self\.presentedFired = YES;/);
    expect(source).toMatch(/self\.terminalEventFired = YES;/);
    expect(source).toMatch(/self\.showCompletionFired = YES;/);
  });

  it('Feed 先绑定根控制器并挂载容器，再触发一次 render', () => {
    const source = readIOSSource('ExpressNativeAd.m');
    const attachStart = source.indexOf('- (void)registerContainerView:');
    const attachEnd = source.indexOf('#pragma mark', attachStart);
    const attachSource = source.slice(attachStart, attachEnd);
    const loadStart = source.indexOf('- (void)nativeExpressAdSuccessToLoad:');
    const loadEnd = source.indexOf(
      '- (void)nativeExpressAdFailToLoad:',
      loadStart
    );
    const loadSource = source.slice(loadStart, loadEnd);

    expect(
      attachSource.indexOf('rootViewController = rootViewController')
    ).toBeLessThan(
      attachSource.indexOf('[containerView addSubview:self.expressAdView]')
    );
    expect(
      attachSource.indexOf('[containerView addSubview:self.expressAdView]')
    ).toBeLessThan(attachSource.indexOf('[self.expressAdView render]'));
    expect(attachSource).toMatch(/!self\.renderRequested && !self\.adRendered/);
    expect(loadSource).not.toContain('[self.expressAdView render]');
    expect(loadSource).toContain('self.loadCompletion(YES, nil)');
  });

  it('初始化时诊断宿主的两项 ATS 媒体例外', () => {
    const source = readIOSSource('PAGSDKService.m');

    expect(source).toContain('NSAllowsArbitraryLoadsInWebContent');
    expect(source).toContain('NSAllowsArbitraryLoadsForMedia');
    expect(source).toContain('[Pangle][ATS]');
  });
});
