# iOS 全屏广告 `FULLSCREEN_BUSY` 调试报告

## 症状

- 第一次激励视频请求没有返回终态。
- 后续激励视频和新插屏请求立即以 `0ms` 返回 `cancelled`。
- 错误持续引用同一个激励请求 ID：`FULLSCREEN_BUSY: 已有全屏广告请求正在执行`。

## 根因

`PangleAdModule.showFullscreenAdV2` 只保存了 `activeFullscreenRequestId`，没有强持有正在展示的 `RewardedAd` 或 `InterstitialAd` 包装对象。加载完成回调退出后，包装对象可能被释放，其穿山甲 delegate 和 completion 不再回调，`finish` 无法执行，原生锁和 JS 锁因此一直占用。

现有 `loadTimeoutMs` 只在素材尚未加载完成时生效，不能处理广告已加载但包装对象提前释放的情况。

## 修复

- `PangleAdModule` 新增强引用 `activeFullscreenAd`。
- 激励视频和新插屏开始展示前保存当前包装对象。
- 对应请求进入终态并释放 `activeFullscreenRequestId` 时，同步释放广告对象。

## 证据

- 新增源码生命周期契约测试，修复前失败、修复后通过。
- `pnpm prepare` 通过。
- `pnpm typecheck` 通过。
- `pnpm exec jest --runInBand`：3 个测试套件、31 个测试全部通过。
- `pnpm lint` 通过。

## 回归测试

`src/__tests__/ios-fullscreen-lifecycle.test.js`

## 关注项

本机未安装完整 Xcode，`xcode-select` 指向 CommandLineTools，无法执行 iOS 示例工程的原生编译和真机广告关闭验证。发布前仍需在配置完整 Xcode 的环境中编译，并在真机依次验证激励视频关闭后可立即展示新插屏。

## 状态

`DONE_WITH_CONCERNS`
