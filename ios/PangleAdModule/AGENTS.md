# ios/PangleAdModule/ — iOS 原生广告模块

## 概览

所有 iOS 广告能力通过 `PangleAdModule` 统一桥接。穿山甲 iOS SDK（`Ads-CN`）通过 Podspec 依赖引入，宿主侧无需手动集成。

## 文件结构

### 核心桥接

| 文件 | 职责 |
|------|------|
| `PangleAdModule.h/.m` | RN 桥接入口：初始化、插屏/激励/全屏公共方法 |
| `SplashAd.h/.m` | 开屏广告加载与展示 |
| `BannerAd.h/.m` | Banner 广告数据层 |
| `BrayantBannerAdView.h/.m` | Banner 原生 UIView |
| `BrayantBannerAdViewManager.h/.m` | Banner 原生组件管理器（RN 侧 `requireNativeComponent` 目标） |
| `FeedAdView.h/.m` | Feed 信息流原生 UIView |
| `ExpressNativeAd.h/.m` | Feed 原生广告渲染器 |
| `FeedAdViewManager.h/.m` | Feed 原生组件管理器 |
| `InterstitialAd.h/.m` | 插屏广告加载与展示 |
| `PAGSDKService.h/.m` | Pangle SDK 服务生命周期管理 |
| `AdResourceStore.h/.m` | 广告资源缓存 |
| `ATTPermissionService.h/.m` | ATT 权限请求 |

## 关键规则

- 所有广告类型共用同一个 `PangleAdModule` 实例
- 初始化仅依赖 `appid`，iOS 不需要 `app`/`uid`/`amount`/`reward`
- 开屏广告 iOS 当前可靠关闭事件为 `onAdClose`
- 激励/全屏视频 iOS 当前复用插屏链路
- 新增广告类型：在 `PangleAdModule.m` 新增 RCT_EXPORT_METHOD，按需创建对应 `.h`/`.m`
