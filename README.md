# react-native-brayant-ad

React Native 国内广告 SDK 封装，当前主要集成穿山甲（Pangle / Ads-CN）。

最近这轮重构后，文档口径以当前代码为准：

- iOS 端广告能力统一由 `PangleAdModule` 承接
- `BannerAdView` 已支持 Android / iOS 同参接入
- Feed 信息流推荐走 `preloadFeedAd + FeedAdView` 的声明式渲染方案
- 业务侧推荐自行封装一层“初始化、预加载、占位态、会员免广告、事件归一化”的组件

## 功能一览

| 能力 | 导出名 | Android | iOS | 说明 |
| --- | --- | --- | --- | --- |
| SDK 初始化 | `init` | ✅ | ✅ | iOS 仅使用 `appid` 初始化 Pangle |
| 权限请求 | `requestPermission` | ✅ | ✅ | Android 请求权限，iOS 请求 ATT |
| 开屏广告 | `dyLoadSplashAd` | ✅ | ✅ | 支持事件监听与 `cleanup()` |
| 开屏预加载 | `preloadSplashAd` / `hasPreloadedSplashAd` / `clearPreloadedSplashAd` | ✅ | ✅ / ✅ / noop | iOS 的 `clearPreloadedSplashAd` 当前无实际清理逻辑 |
| 激励视频 | `startRewardVideo` | ✅ | ✅ | iOS 当前复用插屏链路 |
| 全屏视频 | `startFullScreenVideo` | ✅ | ✅ | iOS 当前复用插屏链路 |
| 插屏广告 | `startInterstitialAd` | ✅ | ✅ | Android 复用全屏视频通道 |
| Feed 信息流 | `preloadFeedAd` / `FeedAdView` | ✅ | ✅ | 推荐声明式组件接入 |
| Draw 信息流 | `loadDrawFeedAd` / `DrawFeedView` | ✅ | ❌ | 仅 Android |
| Banner | `BannerAdView` | ✅ | ✅ | 推荐直接组件渲染 |

## 安装

```bash
pnpm add @24jieqi/react-native-brayant-ad
# 或
npm i @24jieqi/react-native-brayant-ad
# 或
yarn add @24jieqi/react-native-brayant-ad
```

iOS 安装 Pod：

```bash
cd ios && pod install
```

## 原生配置

### Android Maven 仓库

在宿主 App 的 `android/build.gradle` 或统一仓库配置中加入：

```groovy
allprojects {
  repositories {
    google()
    mavenCentral()
    maven { url 'https://artifact.bytedance.com/repository/pangle' }
  }
}
```

### iOS ATT 权限说明

如果业务会调用 `requestPermission()`，请在 `Info.plist` 中声明：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>用于请求广告跟踪授权，以提升广告相关性</string>
```

说明：

- Podspec 已内置 `Ads-CN` 依赖，宿主侧通常不需要额外手动引入穿山甲 iOS SDK
- iOS 初始化实际调用 `PangleAdModule.initialize(appid)`

## 推荐接入顺序

结合当前 iOS 实现与业务侧封装方式，推荐顺序如下：

1. App 启动后尽早调用一次 `init`
2. 在需要展示前做预加载
3. Feed / Banner 统一通过组件渲染，不再自己维护原生容器
4. 开屏 / 激励 / 全屏 / 插屏这类命令式广告，在页面卸载或流程结束时调用 `cleanup()`

一个最小可用初始化示例：

```tsx
import { init, requestPermission } from '@24jieqi/react-native-brayant-ad';

export async function setupAdSDK() {
  await init({
    appid: '你的穿山甲 appid',
    app: '你的应用名',
    uid: '可选用户 ID',
    amount: 1000,
    reward: '金币',
    debug: __DEV__,
  });

  requestPermission();
}
```

`init` 参数说明：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `appid` | `string` | 是 | 穿山甲应用 ID |
| `app` | `string` | 否 | 应用名，仅 Android 侧会继续使用 |
| `uid` | `string` | 否 | 用户标识 |
| `amount` | `number` | 否 | 激励数量 |
| `reward` | `string` | 否 | 激励名称 |
| `debug` | `boolean` | 否 | 调试模式 |

## 推荐业务封装

当前库更适合作为“广告桥接层”，业务侧建议再包一层：

- 初始化守卫：确保 SDK 只初始化一次
- 预加载去重：避免短时间重复请求同一广告位
- 占位态控制：广告超时或失败时快速隐藏骨架屏
- 权益控制：会员、首登用户、免广告用户直接不渲染
- 事件归一化：把原生事件统一为 `onAdLoaded/onAdShow/onAdError/onAdClose`

Feed / Banner 的新用法建议都基于这个思路实现。

## 开屏广告

### 导入

```tsx
import {
  dyLoadSplashAd,
  preloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
} from '@24jieqi/react-native-brayant-ad';
```

### 预加载

```tsx
await preloadSplashAd({ codeid: '你的开屏广告位' });

const preloadState = await hasPreloadedSplashAd();

if (preloadState.hasAd) {
  console.log('开屏广告已就绪', preloadState.status);
}
```

说明：

- Android 会走原生预加载缓存
- iOS 会提前触发 `loadSplashAd`
- `clearPreloadedSplashAd()` 在 Android 有效，iOS 当前为 noop

### 展示

```tsx
const splash = dyLoadSplashAd({
  codeid: '你的开屏广告位',
  anim: 'default',
});

splash.subscribe('onAdShow', () => {
  console.log('开屏开始展示');
});

splash.subscribe('onAdClick', () => {
  console.log('开屏点击');
});

splash.subscribe('onAdClose', () => {
  console.log('开屏关闭');
});

splash.subscribe('onAdError', (error) => {
  console.log('开屏失败', error);
});

await splash.result;

// 流程结束后
splash.cleanup();
```

`dyLoadSplashAd` 参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | 开屏广告位 ID |
| `anim` | `'default' \| 'none' \| 'catalyst' \| 'slide' \| 'fade'` | 否 | Android 开屏动画风格 |

支持事件：

- `onAdError`
- `onAdClick`
- `onAdClose`
- `onAdSkip`
- `onAdShow`
- `onPreloadSuccess`
- `onPreloadFail`

说明：

- iOS 当前主要可靠事件是 `onAdClose`
- 业务侧若对启动流程有更强控制，建议自己封装“预加载 + ready 检查 + 超时兜底”

## 激励视频

```tsx
import { startRewardVideo } from '@24jieqi/react-native-brayant-ad';

const reward = startRewardVideo({
  codeid: '你的激励视频广告位',
});

reward.subscribe('onAdLoaded', () => {
  console.log('激励广告已展示');
});

reward.subscribe('onAdClick', () => {
  console.log('激励广告点击');
});

reward.subscribe('onAdClose', () => {
  console.log('激励广告关闭');
});

reward.subscribe('onAdError', (error) => {
  console.log('激励广告失败', error);
});

await reward.result;
reward.cleanup();
```

说明：

- Android 走独立激励视频模块
- iOS 当前实现复用 `PangleAdModule` 的插屏加载与展示链路，事件接口保持一致

## 全屏视频

```tsx
import { startFullScreenVideo } from '@24jieqi/react-native-brayant-ad';

const full = startFullScreenVideo({
  codeid: '你的全屏视频广告位',
  orientation: 'VERTICAL',
  provider: '头条',
});

full.subscribe('onAdLoaded', () => {
  console.log('全屏视频已展示');
});

full.subscribe('onAdClick', () => {
  console.log('全屏视频点击');
});

full.subscribe('onAdClose', () => {
  console.log('全屏视频关闭');
});

full.subscribe('onAdError', (error) => {
  console.log('全屏视频失败', error);
});

await full.result;
full.cleanup();
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | 广告位 ID |
| `orientation` | `'HORIZONTAL' \| 'VERTICAL'` | 否 | Android 方向参数 |
| `provider` | `'头条' \| '腾讯' \| '快手'` | 否 | Android 广告源 |

## 插屏广告

```tsx
import { startInterstitialAd } from '@24jieqi/react-native-brayant-ad';

const interstitial = startInterstitialAd({
  codeid: '你的插屏广告位',
  orientation: 'VERTICAL',
  provider: '头条',
});

interstitial.subscribe('onAdLoaded', () => {
  console.log('插屏已展示');
});

interstitial.subscribe('onAdClick', () => {
  console.log('插屏点击');
});

interstitial.subscribe('onAdClose', () => {
  console.log('插屏关闭');
});

interstitial.subscribe('onAdError', (error) => {
  console.log('插屏失败', error);
});

await interstitial.result;
interstitial.cleanup();
```

说明：

- iOS 通过 `PangleAdModule.loadInterstitialAd -> isInterstitialAdReady -> showInterstitialAd` 完成展示
- Android 当前复用全屏视频模块通道

## Feed 信息流

这是当前最推荐的接入方式。

### 预加载

```tsx
import { preloadFeedAd } from '@24jieqi/react-native-brayant-ad';

await preloadFeedAd({
  codeid: '你的 Feed 广告位',
  adWidth: 375,
});
```

说明：

- Android 会走原生预加载
- iOS 会直接触发 `loadExpressNativeAdWithAdSize`

### 组件渲染

```tsx
import { FeedAdView } from '@24jieqi/react-native-brayant-ad';

<FeedAdView
  codeid="你的 Feed 广告位"
  adWidth={375}
  visible={true}
  onAdLayout={(event) => {
    console.log('信息流渲染完成', event);
  }}
  onAdError={(event) => {
    console.log('信息流加载失败', event);
  }}
  onAdClick={(event) => {
    console.log('信息流点击', event);
  }}
  onAdClose={(event) => {
    console.log('信息流关闭', event);
  }}
/>
```

`FeedAdView` 参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | 广告位 ID |
| `adWidth` | `number` | 否 | 广告展示宽度，默认 `375` |
| `visible` | `boolean` | 否 | 是否显示，默认 `true` |
| `style` | `ViewStyle` | 否 | 外层容器样式 |
| `onAdLayout` | `(event) => void` | 否 | 渲染完成回调，通常拿它作为加载成功信号 |
| `onAdError` | `(event) => void` | 否 | 加载失败 |
| `onAdClick` | `(event) => void` | 否 | 点击 |
| `onAdClose` | `(event) => void` | 否 | 关闭 |

接入建议：

- 传入真实容器宽度，不要写死过大的 `adWidth`
- 业务侧把 `onAdLayout` 当成“广告真正可展示”的信号
- 可以配合骨架屏、淡入动画、预加载去重一起使用

## Draw 信息流（仅 Android）

```tsx
import { DrawFeedView, loadDrawFeedAd } from '@24jieqi/react-native-brayant-ad';

loadDrawFeedAd({
  appid: '你的 appid',
  codeid: '你的 Draw 广告位',
});

<DrawFeedView
  appid="你的 appid"
  codeid="你的 Draw 广告位"
  visible={true}
  onAdShow={(event) => {
    console.log('Draw 广告展示', event);
  }}
  onAdClick={(event) => {
    console.log('Draw 广告点击', event);
  }}
  onAdError={(event) => {
    console.log('Draw 广告错误', event);
  }}
/>
```

说明：

- 仅 Android 可用
- `appid` 目前主要用于兼容历史调用方式，业务接入时仍建议保留传参

## Banner

`BannerAdView` 现在支持 Android / iOS 共用同一套组件参数。

```tsx
import { BannerAdView } from '@24jieqi/react-native-brayant-ad';

<BannerAdView
  codeid="你的 Banner 广告位"
  adWidth={375}
  adHeight={60}
  visible={true}
  onAdRenderSuccess={(event) => {
    console.log('Banner 渲染成功', event);
  }}
  onAdShow={(event) => {
    console.log('Banner 展示', event);
  }}
  onAdClick={(event) => {
    console.log('Banner 点击', event);
  }}
  onAdDismiss={(event) => {
    console.log('Banner 关闭', event);
  }}
  onAdError={(event) => {
    console.log('Banner 加载失败', event);
  }}
  onAdDislike={(event) => {
    console.log('Banner 不感兴趣', event);
  }}
/>
```

`BannerAdView` 参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | Banner 广告位 ID |
| `adWidth` | `number` | 否 | 宽度，默认 `320` |
| `adHeight` | `number` | 否 | 高度，默认 `50` |
| `visible` | `boolean` | 否 | 是否显示，默认 `true` |
| `style` | `ViewStyle` | 否 | 容器样式 |
| `onAdRenderSuccess` | `(event) => void` | 否 | 渲染成功 |
| `onAdError` | `(event) => void` | 否 | 加载失败 |
| `onAdDismiss` | `(event) => void` | 否 | 关闭 |
| `onAdClick` | `(event) => void` | 否 | 点击 |
| `onAdShow` | `(event) => void` | 否 | 展示 |
| `onAdDislike` | `(event) => void` | 否 | 不感兴趣 |

说明：

- iOS 内部会先加载 Banner，再根据容器 `tag` 调用原生展示
- iOS 当前没有独立的 `onAdDislike` 语义，业务上不要依赖它
- 推荐在业务侧自行做占位态与渐显，而不是把 Banner 区域直接闪出来

## 广告相关导出

```ts
import {
  init,
  requestPermission,
  loadFeedAd,
  preloadFeedAd,
  dyLoadSplashAd,
  preloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
  startRewardVideo,
  startFullScreenVideo,
  startInterstitialAd,
  loadDrawFeedAd,
  DrawFeedView,
  FeedAdView,
  BannerAdView,
} from '@24jieqi/react-native-brayant-ad';
```

## 常见问题

### 1. 提示 `doesn't seem to be linked`

- 确认安装依赖后已经重新编译 App
- iOS 确认执行过 `pod install`
- 确认当前不是 Expo Go 环境

### 2. iOS 广告不展示

- 先确认 `init({ appid })` 已执行且成功
- 如果调用了 `requestPermission()`，确认 `Info.plist` 已配置 `NSUserTrackingUsageDescription`
- Feed / Banner 建议先走预加载，再挂载组件

### 3. 开屏广告白屏或超时

- 启动后尽早调用 `preloadSplashAd`
- 业务侧增加 ready 检查和超时兜底
- Android 用完后可调用 `clearPreloadedSplashAd()`

### 4. 事件重复触发或内存泄漏

- 每次命令式广告实例使用完成后调用 `cleanup()`
- 避免在同一实例上重复绑定同一事件

## 本地开发

```bash
pnpm typecheck
pnpm lint
pnpm test
pnpm prepare
```

如果修改了 `src/`、`ios/`、`android/` 中的实现，发布或联调前建议至少执行：

```bash
pnpm prepare
```
