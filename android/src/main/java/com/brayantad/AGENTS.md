# android/src/main/java/com/brayantad/ — Android 原生广告模块

## 概览

Android 广告能力通过 `BrayantAdModule`（RN 桥接）和 `AdManager`（广告管理器）接入穿山甲 SDK（`com.pangle.cn:ads-sdk-pro:7.6.1.2`）。Draw 信息流为 Android 独占能力。

## 分包结构

### 广告类型包（`dy/`）

| 包 | 文件 | 职责 |
|------|------|------|
| `dy/banner/` | `BannerAdModule.java`, `BannerAdViewManager.java`, `view/BannerAdView.java` | Banner 组件 |
| `dy/drawFeed/` | `DrawFeedViewManager.java`, `DrawFeedViewModule.java`, `view/DrawFeedView.java` | Draw 信息流（仅 Android） |
| `dy/feedAd/` | `FeedAdViewManager.java`, `view/FeedAdView.java` | Feed 信息流组件 |
| `dy/fullScreen/` | `FullScreenVideoModule.java`, `activity/FullScreenActivity.java` | 全屏视频 |
| `dy/rewardVideo/` | `RewardVideoModule.java`, `activity/RewardActivity.java` | 激励视频 |
| `dy/splash/` | `SplashAdModule.java`, `activity/SplashActivity.java` | 开屏广告 |
| `dy/service/` | `CSJSplashAd.java` | CSJ 开屏广告服务 |

### 基础设施

| 文件 | 职责 |
|------|------|
| `AdManager.java` | 广告管理器主入口 |
| `BrayantAdModule.java` | RN 原生模块桥接（ReactContextBaseJavaModule） |
| `BrayantAdPackage.java` | RN 包注册 |
| `WeakHandler.java` | 弱引用 Handler（根级 + dy 级各一份） |
| `core/AdResourcePool.java` | 广告资源池 |
| `core/RewardedAdController.java` | v2 激励视频加载、展示和奖励回调 |
| `core/InterstitialAdController.java` | v2 新插屏加载与展示 |
| `utils/` | `DislikeDialog.java`, `RewardBundleModel.java`, `TToast.java`, `Utils.java` |

## 关键规则

- 所有 `ViewManager` 必须注册到 `BrayantAdPackage.createViewManagers()`
- 新插屏按穿山甲规范使用 `loadFullScreenVideoAd`；v2 直接在当前 Activity 展示
- `RewardVideoModule` / `FullScreenVideoModule` 仅用于 legacy 兼容，新功能统一从 `AdManager` 进入
- Draw 信息流不提供 iOS 实现，JS 侧需 `Platform.OS === 'android'` 保护
- 新增广告类型：创建对应包 → 实现 Module + ViewManager/Activity → 注册到 `BrayantAdPackage`
