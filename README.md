# react-native-brayant-ad

React Native 国内广告 SDK 封装，当前主要集成穿山甲（Pangle / Ads-CN）。

支持能力：

- 开屏广告
- 激励视频
- 全屏视频
- 插屏广告
- Feed 信息流
- Draw 信息流
- Banner

当前实现口径：

- Android 与 iOS 都可使用同一个 npm 包接入
- iOS 广告能力统一通过 `PangleAdModule` 承接
- Feed / Banner 推荐使用声明式组件方式接入
- Draw 信息流当前仅支持 Android

## 目录

- [功能支持](#功能支持)
- [安装](#安装)
- [原生配置](#原生配置)
- [3 分钟快速开始](#3-分钟快速开始)
- [API 说明](#api-说明)
- [常见问题](#常见问题)
- [本地开发](#本地开发)

## 功能支持

| 能力 | 导出名 | Android | iOS | 备注 |
| --- | --- | --- | --- | --- |
| SDK 初始化 | `init` | ✅ | ✅ | iOS 初始化仅依赖 `appid` |
| 权限请求 | `requestPermission` | ✅ | ✅ | Android 请求权限，iOS 请求 ATT |
| 开屏广告 | `dyLoadSplashAd` | ✅ | ✅ | 支持预加载辅助方法 |
| 开屏预加载 | `preloadSplashAd` | ✅ | ✅ | iOS 为兼容实现 |
| 开屏缓存检测 | `hasPreloadedSplashAd` | ✅ | ✅ | 用于判断是否可直接展示 |
| 开屏缓存清理 | `clearPreloadedSplashAd` | ✅ | ✅ | iOS 当前为 noop |
| 激励视频 | `startRewardVideo` | ✅ | ✅ | iOS 当前复用插屏展示链路 |
| 全屏视频 | `startFullScreenVideo` | ✅ | ✅ | iOS 当前复用插屏展示链路 |
| 插屏广告 | `startInterstitialAd` | ✅ | ✅ | Android 复用全屏视频通道 |
| Feed 信息流 | `preloadFeedAd` / `FeedAdView` | ✅ | ✅ | 推荐方式 |
| Draw 信息流 | `loadDrawFeedAd` / `DrawFeedView` | ✅ | ❌ | 仅 Android |
| Banner | `BannerAdView` | ✅ | ✅ | Android / iOS 同参接入 |

## 安装

```bash
pnpm add @24jieqi/react-native-brayant-ad
# 或
npm i @24jieqi/react-native-brayant-ad
# 或
yarn add @24jieqi/react-native-brayant-ad
```

安装后重新编译工程，不要只做热更新。

### iOS

在宿主 App 的 `ios` 目录执行：

```bash
cd ios && pod install
```

## 原生配置

### Android

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

### iOS

如果业务需要调用 `requestPermission()` 请求 ATT，请在宿主 App 的 `Info.plist` 中声明：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>用于请求广告跟踪授权，以提升广告相关性</string>
```

说明：

- 当前 Podspec 已内置 `Ads-CN`
- 宿主侧通常不需要再手动单独引入穿山甲 iOS SDK
- iOS 侧广告在运行前必须先完成 `init({ appid })`

## 3 分钟快速开始

如果你只想先把 SDK 跑起来，按下面 4 步做即可。

### 1. 初始化 SDK

建议在 App 启动后尽早执行一次，并且只执行一次。

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

### 2. 预加载 Feed 广告

```tsx
import { preloadFeedAd } from '@24jieqi/react-native-brayant-ad';

await preloadFeedAd({
  codeid: '你的 Feed 广告位',
  adWidth: 375,
});
```

### 3. 渲染 Feed 广告组件

```tsx
import { FeedAdView } from '@24jieqi/react-native-brayant-ad';

<FeedAdView
  codeid="你的 Feed 广告位"
  adWidth={375}
  visible={true}
  onAdLayout={(event) => {
    console.log('广告渲染成功', event);
  }}
  onAdError={(event) => {
    console.log('广告加载失败', event);
  }}
/>
```

### 4. 命令式广告记得释放监听

开屏、激励、全屏、插屏这类 API 都会返回广告实例。使用完成后记得调用 `cleanup()`，避免监听重复触发。

```tsx
import { startInterstitialAd } from '@24jieqi/react-native-brayant-ad';

const ad = startInterstitialAd({ codeid: '你的插屏广告位' });

try {
  await ad.result;
} finally {
  ad.cleanup();
}
```

## API 说明

### `init`

初始化广告 SDK。

```tsx
import { init } from '@24jieqi/react-native-brayant-ad';

await init({
  appid: '你的穿山甲 appid',
  app: '你的应用名',
  uid: '用户 ID',
  amount: 1000,
  reward: '金币',
  debug: false,
});
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `appid` | `string` | 是 | 穿山甲应用 ID |
| `app` | `string` | 否 | 应用名 |
| `uid` | `string` | 否 | 用户标识 |
| `amount` | `number` | 否 | 激励数量 |
| `reward` | `string` | 否 | 激励名称 |
| `debug` | `boolean` | 否 | 调试模式 |

建议：

- 整个 App 生命周期内只初始化一次
- iOS 广告展示前必须完成初始化

### `requestPermission`

请求广告相关权限。

```tsx
import { requestPermission } from '@24jieqi/react-native-brayant-ad';

requestPermission();
```

说明：

- Android 会调用原生权限请求
- iOS 会请求 ATT 授权
- 如果 iOS 没配置 `NSUserTrackingUsageDescription`，调用时会有问题

### 开屏广告

导入：

```tsx
import {
  dyLoadSplashAd,
  preloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
} from '@24jieqi/react-native-brayant-ad';
```

#### 预加载

```tsx
await preloadSplashAd({
  codeid: '你的开屏广告位',
});

const state = await hasPreloadedSplashAd();

if (state.hasAd) {
  console.log('开屏广告已可展示');
}
```

#### 展示

```tsx
const splash = dyLoadSplashAd({
  codeid: '你的开屏广告位',
  anim: 'default',
});

splash.subscribe('onAdShow', () => {
  console.log('开屏展示');
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

try {
  await splash.result;
} finally {
  splash.cleanup();
}
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | 开屏广告位 ID |
| `anim` | `'default' \| 'none' \| 'catalyst' \| 'slide' \| 'fade'` | 否 | Android 开屏动画 |

支持事件：

- `onAdError`
- `onAdClick`
- `onAdClose`
- `onAdSkip`
- `onAdShow`
- `onPreloadSuccess`
- `onPreloadFail`

说明：

- Android 推荐先 `preloadSplashAd` 再展示
- iOS 当前主要可靠关闭事件为 `onAdClose`
- `clearPreloadedSplashAd()` 在 Android 有意义，iOS 当前无实际清理逻辑

### 激励视频

```tsx
import { startRewardVideo } from '@24jieqi/react-native-brayant-ad';

const reward = startRewardVideo({
  codeid: '你的激励广告位',
});

reward.subscribe('onAdLoaded', () => {
  console.log('激励广告已就绪或已展示');
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

try {
  await reward.result;
} finally {
  reward.cleanup();
}
```

说明：

- Android 走独立激励视频模块
- iOS 当前实现复用插屏链路

### 全屏视频

```tsx
import { startFullScreenVideo } from '@24jieqi/react-native-brayant-ad';

const full = startFullScreenVideo({
  codeid: '你的全屏视频广告位',
  orientation: 'VERTICAL',
  provider: '头条',
});

full.subscribe('onAdLoaded', () => {
  console.log('全屏视频已就绪或已展示');
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

try {
  await full.result;
} finally {
  full.cleanup();
}
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | 广告位 ID |
| `orientation` | `'HORIZONTAL' \| 'VERTICAL'` | 否 | Android 广告方向 |
| `provider` | `'头条' \| '腾讯' \| '快手'` | 否 | Android 广告源 |

### 插屏广告

```tsx
import { startInterstitialAd } from '@24jieqi/react-native-brayant-ad';

const interstitial = startInterstitialAd({
  codeid: '你的插屏广告位',
  orientation: 'VERTICAL',
  provider: '头条',
});

interstitial.subscribe('onAdLoaded', () => {
  console.log('插屏广告已就绪或已展示');
});

interstitial.subscribe('onAdClick', () => {
  console.log('插屏广告点击');
});

interstitial.subscribe('onAdClose', () => {
  console.log('插屏广告关闭');
});

interstitial.subscribe('onAdError', (error) => {
  console.log('插屏广告失败', error);
});

try {
  await interstitial.result;
} finally {
  interstitial.cleanup();
}
```

说明：

- iOS 通过 `loadInterstitialAd -> isInterstitialAdReady -> showInterstitialAd` 展示
- Android 当前复用全屏视频模块通道

### Feed 信息流

推荐组合：`preloadFeedAd + FeedAdView`

#### 预加载

```tsx
import { preloadFeedAd } from '@24jieqi/react-native-brayant-ad';

await preloadFeedAd({
  codeid: '你的 Feed 广告位',
  adWidth: 375,
});
```

#### 组件

```tsx
import { FeedAdView } from '@24jieqi/react-native-brayant-ad';

<FeedAdView
  codeid="你的 Feed 广告位"
  adWidth={375}
  visible={true}
  onAdLayout={(event) => {
    console.log('Feed 广告渲染完成', event);
  }}
  onAdError={(event) => {
    console.log('Feed 广告失败', event);
  }}
  onAdClick={(event) => {
    console.log('Feed 广告点击', event);
  }}
  onAdClose={(event) => {
    console.log('Feed 广告关闭', event);
  }}
/>
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | 广告位 ID |
| `adWidth` | `number` | 否 | 广告宽度，默认 `375` |
| `visible` | `boolean` | 否 | 是否显示，默认 `true` |
| `style` | `ViewStyle` | 否 | 容器样式 |
| `onAdLayout` | `(event) => void` | 否 | 广告布局完成回调 |
| `onAdError` | `(event) => void` | 否 | 广告失败回调 |
| `onAdClick` | `(event) => void` | 否 | 点击回调 |
| `onAdClose` | `(event) => void` | 否 | 关闭回调 |

接入建议：

- `adWidth` 请传实际容器宽度
- 建议把 `onAdLayout` 作为“广告可显示”的信号
- 建议业务侧自行补一层骨架屏、超时控制、会员免广告逻辑

### Draw 信息流

当前仅支持 Android。

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
    console.log('Draw 广告失败', event);
  }}
/>
```

说明：

- 仅 Android 可用
- 当前类型定义中 `appid` 仍为必传，示例中请保留

### Banner

`BannerAdView` 在 Android / iOS 使用同一套参数。

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
    console.log('Banner 失败', event);
  }}
  onAdDislike={(event) => {
    console.log('Banner 不感兴趣', event);
  }}
/>
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `codeid` | `string` | 是 | Banner 广告位 ID |
| `adWidth` | `number` | 否 | 宽度，默认 `320` |
| `adHeight` | `number` | 否 | 高度，默认 `50` |
| `visible` | `boolean` | 否 | 是否显示，默认 `true` |
| `style` | `ViewStyle` | 否 | 容器样式 |
| `onAdRenderSuccess` | `(event) => void` | 否 | 渲染完成 |
| `onAdError` | `(event) => void` | 否 | 加载失败 |
| `onAdDismiss` | `(event) => void` | 否 | 关闭 |
| `onAdClick` | `(event) => void` | 否 | 点击 |
| `onAdShow` | `(event) => void` | 否 | 展示 |
| `onAdDislike` | `(event) => void` | 否 | 不感兴趣 |

说明：

- iOS 内部会先加载，再根据组件容器展示 Banner
- iOS 当前不要依赖 `onAdDislike`
- 建议业务侧自己做占位态和渐显，体验更稳定

### 导出清单

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

### 提示 `doesn't seem to be linked`

检查下面 3 件事：

1. 安装依赖后是否重新编译了 App
2. iOS 是否执行过 `pod install`
3. 是否运行在 Expo Go 中

### iOS 广告不展示

按顺序检查：

1. 是否已经调用过 `init({ appid })`
2. `appid` 和广告位 ID 是否是 iOS 对应的真实值
3. 如果调用了 `requestPermission()`，`Info.plist` 是否已配置 `NSUserTrackingUsageDescription`
4. Feed / Banner 是否在初始化完成后再渲染

### 开屏广告白屏或超时

建议：

1. App 启动后尽早 `preloadSplashAd`
2. 展示前用 `hasPreloadedSplashAd()` 判断
3. 业务侧补一层超时兜底
4. Android 使用后可调用 `clearPreloadedSplashAd()`

### 事件重复触发

最常见原因是旧实例没释放。

处理方式：

1. 命令式广告使用完成后调用 `cleanup()`
2. 避免在同一个实例上重复 `subscribe`

## 本地开发

```bash
pnpm typecheck
pnpm lint
pnpm test
pnpm prepare
```

如果修改了 `src/`、`ios/`、`android/` 中的实现，联调前建议至少执行：

```bash
pnpm prepare
```
