const fs = require('fs');
const path = require('path');

describe('iOS 全屏广告生命周期', () => {
  const source = fs.readFileSync(
    path.resolve(__dirname, '../../ios/PangleAdModule/PangleAdModule.m'),
    'utf8'
  );

  it('在展示期间强持有广告对象，并在请求终态释放', () => {
    expect(source).toMatch(
      /@property\(nonatomic, strong, nullable\) NSObject \*activeFullscreenAd;/
    );
    expect(source.match(/self\.activeFullscreenAd = ad;/g)).toHaveLength(2);
    expect(source).toMatch(
      /self\.activeFullscreenRequestId = nil;\s+self\.activeFullscreenAd = nil;/
    );
  });
});
