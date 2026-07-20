# react-native-brayant-ad

`@24jieqi/react-native-brayant-ad` 是 React Native 国内广告 SDK 封装，当前主要接入穿山甲（Pangle / Ads-CN）。库内已经重构出一套 v2 API，用统一的 `AdRequest` 描述广告请求，支持初始化防重复、候选广告位、预加载令牌和统一事件流。

- 当前版本：`1.2.3`
- Android SDK：`com.pangle.cn:ads-sdk-pro:7.6.1.2`
- iOS SDK：`Ads-CN >= 7.6.0.4`
- React Native：以库工程当前配置 `0.74.x` 验证
- Expo Go：不支持，安装后必须重新构建原生应用

## 功能支持

| 能力 | 推荐 API | Android | iOS | 说明 |
| --- | --- | --- | --- | --- |
| SDK 初始化 | `initializeAdSdk` | 支持 | 支持 | v2 推荐，支持防重复初始化和隐私门控 |
| 权限请求 | `requestPermission` | 支持 | 支持 | Android 请求广告 SDK 权限，iOS 请求 ATT |
| Feed 信息流 | `createAdRequest` + `preloadFeedAd` + `FeedAd` | 支持 | 支持 | 推荐使用 v2 组件 |
| Banner | `createAdRequest` + `preloadBannerAd` + `BannerAd` | 支持 | 支持 | 推荐使用 v2 组件 |
| 开屏广告 | `createAdRequest` + `preloadSplashAd` + `showSplashAd` | 支持 | 支持 | v2 推荐，返回统一展示结果 |
| 激励视频 | `preloadRewardedAd` + `showRewardedAd` | 支持 | 支持 | v2 推荐，支持奖励校验 |
| 新插屏 | `preloadInterstitialAd` + `showInterstitialAd` | 支持 | 支持 | v2 推荐，支持全屏/半屏代码位 |
| legacy 全屏 API | `startRewardVideo` / `startFullScreenVideo` / `startInterstitialAd` | 支持 | 支持 | 兼容适配层，新接入请使用 v2 |
| Draw 信息流 | `loadDrawFeedAd` + `DrawFeedView` | 支持 | 不支持 | Android 独占能力 |
| legacy 组件 | `FeedAdView` / `BannerAdView` | 支持 | 支持 | 旧版组件仍导出，建议新接入使用 v2 |

## 安装

```bash
pnpm add @24jieqi/react-native-brayant-ad
# 或
npm install @24jieqi/react-native-brayant-ad
# 或
yarn add @24jieqi/react-native-brayant-ad
```

安装后重新编译 App。不要只做 Metro 热更新。

### Android 配置

宿主工程需要能访问穿山甲 Maven 仓库。通常在 `android/build.gradle` 或统一仓库配置中加入：

```groovy
allprojects {
  repositories {
    google()
    mavenCentral()
    maven { url 'https://artifact.bytedance.com/repository/pangle' }
  }
}
```

库默认配置：

| 项 | 值 |
| --- | --- |
| `minSdkVersion` | `24` |
| `targetSdkVersion` | `34` |
| `compileSdkVersion` | `34` |
| AndroidX | 需要 |

### iOS 配置

在宿主 App 的 `ios` 目录执行：

```bash
cd ios
pod install
```

Podspec 已声明 `Ads-CN >= 7.6.0.4`，宿主侧通常不需要再单独引入穿山甲 iOS SDK。

穿山甲或广告主的图片、视频素材可能使用 HTTP 地址。宿主 App 必须在
`Info.plist` 中加入下面的 ATS 例外，否则 SDK 可能回调渲染成功，但图片
区域仍显示白色：

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

不要同时声明 `NSAllowsArbitraryLoadsInWebContent`、
`NSAllowsArbitraryLoadsForMedia` 或 `NSAllowsLocalNetworking`。iOS 10 及以后，
只要存在其中任意一个键（即使值为 `NO`），系统就会忽略
`NSAllowsArbitraryLoads`，导致 SDK 通过 `URLSession` 下载的 HTTP 图片继续被
ATS 拦截。`InWebContent` 只作用于 `WKWebView`，`ForMedia` 只作用于
AVFoundation，二者都不覆盖原生图片请求。

App Store 审核如询问 ATS 用途，可说明：例外仅用于第三方广告 SDK 动态下发的
广告主图片/视频素材，应用无法预先枚举所有广告素材域名；应用自身的业务接口
仍只使用 HTTPS。该配置是穿山甲 iOS 官方接入文档针对客户 HTTP 素材要求的工程
配置。参考：[穿山甲 iOS SDK 接入配置](https://www.csjplatform.com/supportcenter/28721)、
[Apple ATS 配置说明](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSAppTransportSecurity)。

如果会调用 `requestPermission()` 请求 ATT，在宿主 App 的 `Info.plist` 中加入：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>用于请求广告跟踪授权，以提升广告相关性</string>
```

## 快速开始：展示一个 Feed 广告

下面示例使用 v2 推荐 API。流程是：初始化 SDK，创建广告请求，预加载，渲染组件。

```tsx
import React, { useEffect, useMemo, useState } from 'react';
import { Dimensions, View } from 'react-native';
import {
  FeedAd,
  createAdRequest,
  initializeAdSdk,
  preloadFeedAd,
  requestPermission,
} from '@24jieqi/react-native-brayant-ad';
import type {
  AdEvent,
  AdPreloadToken,
} from '@24jieqi/react-native-brayant-ad';

const adWidth = Math.floor(Dimensions.get('window').width);

export function HomeFeedAd() {
  const [preloadToken, setPreloadToken] = useState<AdPreloadToken>();
  const [ready, setReady] = useState(false);

  const request = useMemo(
    () =>
      createAdRequest({
        format: 'feed',
        slotIds: ['你的 Feed 广告位 ID'],
        scene: 'home-feed',
        size: { width: adWidth },
      }),
    []
  );

  useEffect(() => {
    let mounted = true;

    async function setup() {
      await initializeAdSdk({
        appId: '你的穿山甲 appid',
        appName: '你的应用名',
        debug: __DEV__,
        allowInitialization: true,
      });

      requestPermission();

      const token = await preloadFeedAd(request);
      if (mounted) {
        setPreloadToken(token);
        setReady(true);
      }
    }

    setup().catch((error) => {
      console.log('广告初始化或预加载失败', error);
    });

    return () => {
      mounted = false;
    };
  }, [request]);

  if (!ready) {
    return <View style={{ width: adWidth, height: 1 }} />;
  }

  return (
    <FeedAd
      request={request}
      preloadToken={preloadToken}
      onEvent={(event: AdEvent) => {
        console.log('Feed 广告事件', event.state, event);
      }}
    />
  );
}
```

## v2 核心概念

### 1. `initializeAdSdk`

初始化广告 SDK。建议在 App 启动后、业务确认允许初始化广告 SDK 时执行。

```tsx
import { initializeAdSdk } from '@24jieqi/react-native-brayant-ad';

const result = await initializeAdSdk({
  appId: '你的穿山甲 appid',
  appName: '你的应用名',
  debug: __DEV__,
  allowInitialization: true,
});

console.log(result.initialized, result.reused);
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `appId` | `string` | 是 | 穿山甲应用 ID |
| `appName` | `string` | 否 | 应用名 |
| `debug` | `boolean` | 否 | 是否开启调试 |
| `allowInitialization` | `boolean` | 是 | 传 `false` 时不会调用原生初始化 |

返回值：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `initialized` | `boolean` | 本次是否已经完成初始化 |
| `reused` | `boolean` | 是否复用了同一个 `appId` 的已有初始化结果 |

注意：

- 同一个 `appId` 重复调用会复用结果。
- 并发调用同一个初始化任务时，原生模块只会收到一次初始化请求。
- 初始化失败后可以再次重试。

### 2. `createAdRequest`

创建广告请求对象。v2 的 Feed、Banner、开屏都使用这个对象传参。

```tsx
import { createAdRequest } from '@24jieqi/react-native-brayant-ad';

const request = createAdRequest({
  format: 'banner',
  slotIds: ['主广告位', '备用广告位'],
  scene: 'message-list',
  size: { width: 320, height: 50 },
});
```

参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `format` | `'feed' \| 'banner' \| 'splash'` | 是 | 广告类型 |
| `slotIds` | `string[]` | 是 | 广告位列表，按优先级排序 |
| `scene` | `string` | 是 | 业务场景标识，便于调用侧追踪 |
| `size` | `{ width: number; height?: number }` | 否 | 广告尺寸 |
| `requestId` | `string` | 否 | 自定义请求 ID，不传会自动生成 |

行为：

- 会去掉空广告位和重复广告位。
- `slotIds` 清洗后为空会抛出 `广告请求至少需要一个有效广告位`。
- 多个广告位表示候选列表。主广告位失败时，组件会尝试后续广告位。

### 3. 预加载令牌

所有 `preload*` 方法都会返回 `AdPreloadToken`。组件或对应的 `show*` 方法会优先消费同规格令牌。

```tsx
const token = await preloadBannerAd(request);
```

预加载规则：

- 同一规格的并发预加载会合并成一次原生请求。
- 同一规格已有未过期令牌时会直接复用。
- 令牌按 `format + slotIds + width + height` 隔离。
- 令牌被组件或展示方法消费后，不会再次返回。
- 请求类型必须匹配，例如 `preloadBannerAd(feedRequest)` 会被拒绝。

### 4. 统一事件 `AdEvent`

v2 组件和开屏展示通过 `onEvent` 返回统一事件。

```ts
interface AdEvent {
  requestId: string;
  format: 'feed' | 'banner' | 'splash';
  slotId: string;
  state:
    | 'idle'
    | 'loading'
    | 'loaded'
    | 'rendering'
    | 'rendered'
    | 'presented'
    | 'terminal';
  action?: 'click';
  source: 'preloaded' | 'realtime';
  elapsedMs: number;
  width?: number;
  height?: number;
  error?: {
    code: string;
    message: string;
    nativeCode?: number;
  };
}
```

常用判断：

- `state === 'rendered'`：信息流已经渲染出尺寸。
- `state === 'presented'`：广告已展示。
- `state === 'terminal' && error`：当前广告位失败，可能已经触发候选广告位回退。
- `action === 'click'`：用户点击广告。

## Feed 信息流（v2 推荐）

```tsx
import {
  FeedAd,
  createAdRequest,
  preloadFeedAd,
} from '@24jieqi/react-native-brayant-ad';

const request = createAdRequest({
  format: 'feed',
  slotIds: ['主 Feed 广告位', '备用 Feed 广告位'],
  scene: 'article-list',
  size: { width: 375 },
});

const token = await preloadFeedAd(request);

<FeedAd
  request={request}
  preloadToken={token}
  candidateTimeoutMs={6000}
  visible={true}
  style={{ marginVertical: 12 }}
  onEvent={(event) => {
    console.log('Feed event', event);
  }}
/>;
```

`FeedAd` props：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `request` | `AdRequest` | 是 | 无 | `format` 必须是 `feed` |
| `preloadToken` | `AdPreloadToken` | 否 | 自动领取同规格令牌 | 预加载结果 |
| `visible` | `boolean` | 否 | `true` | `false` 时返回 `null` |
| `style` | `StyleProp<ViewStyle>` | 否 | 无 | 外层容器样式 |
| `candidateTimeoutMs` | `number` | 否 | `6000` | 当前候选广告位加载或渲染超时时间 |
| `onEvent` | `(event: AdEvent) => void` | 否 | 无 | 统一事件回调 |

说明：

- 宽度来自 `request.size.width`，未传时默认 `375`。
- 初始高度来自 `request.size.height`，未传时先使用 `1`，渲染成功后按原生事件高度更新。
- 预加载命中备用广告位时，会先展示该广告位；失败后再回到请求中的其他广告位。

## Banner（v2 推荐）

```tsx
import {
  BannerAd,
  createAdRequest,
  preloadBannerAd,
} from '@24jieqi/react-native-brayant-ad';

const request = createAdRequest({
  format: 'banner',
  slotIds: ['主 Banner 广告位', '备用 Banner 广告位'],
  scene: 'home-bottom',
  size: { width: 320, height: 50 },
});

const token = await preloadBannerAd(request);

<BannerAd
  request={request}
  preloadToken={token}
  visible={true}
  onEvent={(event) => {
    console.log('Banner event', event);
  }}
/>;
```

`BannerAd` props 与 `FeedAd` 共用 `InlineAdProps`，但不会使用 `candidateTimeoutMs`。

默认尺寸：

| 字段 | 默认值 |
| --- | --- |
| `request.size.width` | `320` |
| `request.size.height` | `50` |

## 开屏广告（v2 推荐）

```tsx
import {
  createAdRequest,
  preloadSplashAd,
  showSplashAd,
} from '@24jieqi/react-native-brayant-ad';

const request = createAdRequest({
  format: 'splash',
  slotIds: ['你的开屏广告位'],
  scene: 'app-launch',
});

await preloadSplashAd(request);

const result = await showSplashAd({
  request,
  timeoutMs: 8000,
  onEvent: (event) => {
    console.log('Splash event', event);
  },
});

if (result.status === 'closed' || result.status === 'skipped') {
  console.log('开屏广告展示结束');
}
```

`showSplashAd` 参数：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `request` | `AdRequest` | 是 | 无 | `format` 必须是 `splash` |
| `preloadToken` | `AdPreloadToken` | 否 | 自动领取同规格令牌 | 指定要消费的预加载令牌 |
| `timeoutMs` | `number` | 否 | `8000` | 原生展示超时时间 |
| `onEvent` | `(event: AdEvent) => void` | 否 | 无 | 统一事件回调 |

返回值：

```ts
interface FullscreenAdResult {
  requestId: string;
  slotId: string;
  status: 'closed' | 'skipped' | 'failed' | 'cancelled';
  elapsedMs: number;
  error?: {
    code: string;
    message: string;
    nativeCode?: number;
  };
}
```

注意：

- `showSplashAd` 同一时间只允许一个开屏请求执行。
- 如果已有全屏广告正在执行，后续请求会返回 `status: 'cancelled'`，错误码为 `FULLSCREEN_BUSY`。
- `request.format` 不是 `splash` 时会抛出错误。

## 激励视频（v2 推荐）

激励视频支持预加载和即时加载。调用 `showRewardedAd` 时如果存在同规格的预加载令牌会自动消费；没有令牌或令牌已过期时会实时加载。

```tsx
import {
  createAdRequest,
  preloadRewardedAd,
  showRewardedAd,
} from '@24jieqi/react-native-brayant-ad';

const request = createAdRequest({
  format: 'rewarded',
  slotIds: ['主激励代码位', '备用激励代码位'],
  scene: 'daily-check-in',
  reward: {
    userId: 'user-123',
    rewardName: '金币',
    rewardAmount: 100,
    extra: JSON.stringify({ orderId: 'reward-order-001' }),
  },
});

// 可选。建议在用户进入可能触发广告的页面时预加载。
await preloadRewardedAd(request);

const result = await showRewardedAd({
  request,
  loadTimeoutMs: 10_000,
  onEvent: (event) => {
    console.log('Rewarded event', event.state, event.action, event);
  },
});

if (result.reward?.valid) {
  // 只在奖励校验有效时发奖。
  console.log('发放奖励', result.reward.name, result.reward.amount);
} else {
  console.log('未获得奖励', result.status, result.reward?.error);
}
```

`reward` 参数：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `userId` | `string` | 服务端校验时必填 | 穿山甲服务端回调使用的用户标识 |
| `rewardName` | `string` | 否 | 广告内展示的奖励名称；接口值优先于平台配置 |
| `rewardAmount` | `number` | 否 | 正整数，广告内展示的奖励数量 |
| `extra` | `string` | 否 | JSON 对象序列化字符串，用于服务端回调透传 |

客户端校验和服务端校验最终都会通过 `result.reward.valid` 返回。使用服务端校验时，需要在穿山甲平台配置回调 URL，并保证 `userId` 非空。SDK 只负责透传参数和结果，不会调用业务发奖接口。

> 不要根据 `videoCompleted`、`status === 'closed'` 或关闭事件直接发奖。视频播放完成、广告关闭与奖励验证是三个不同状态，必须以 `result.reward?.valid === true` 为准。

## 新插屏（v2 推荐）

穿山甲的新插屏在 Android 使用 `loadFullScreenVideoAd`，在 iOS 使用 `BUNativeExpressFullscreenVideoAd`。全屏、半屏或优选样式由穿山甲平台上的代码位配置决定。

```tsx
import {
  createAdRequest,
  preloadInterstitialAd,
  showInterstitialAd,
} from '@24jieqi/react-native-brayant-ad';

const request = createAdRequest({
  format: 'interstitial',
  slotIds: ['主新插屏代码位', '备用新插屏代码位'],
  scene: 'level-complete',
});

await preloadInterstitialAd(request);

const result = await showInterstitialAd({
  request,
  loadTimeoutMs: 10_000,
  onEvent: (event) => {
    console.log('Interstitial event', event);
  },
});

if (result.status === 'failed') {
  console.log(result.error?.code, result.error?.message);
}
```

新插屏应在页面切换、关卡结束、视频暂停等自然中断点展示，不应在用户操作过程中突然弹出。

### 全屏广告事件

| `state` / `action` | 说明 |
| --- | --- |
| `state: 'loading'` | 开始实时加载 |
| `state: 'loaded'` | 素材已缓存，可以流畅展示 |
| `state: 'presented'` | 广告已经展示 |
| `action: 'click'` | 用户点击广告 |
| `action: 'skip'` | 用户跳过视频 |
| `action: 'video-complete'` | 视频素材播放完成，不代表奖励有效 |
| `action: 'reward'` | 收到激励校验结果，`event.reward` 包含详情 |
| `state: 'terminal'` | 本次请求已经结束 |

展示结果的 `status` 为 `closed`、`skipped`、`failed` 或 `cancelled`。常用稳定错误码：

| 错误码 | 说明 |
| --- | --- |
| `FULLSCREEN_BUSY` | 已有开屏、激励或插屏正在执行 |
| `SDK_NOT_INITIALIZED` | Android 广告 SDK 尚未初始化 |
| `ACTIVITY_UNAVAILABLE` / `VIEW_CONTROLLER_UNAVAILABLE` | 当前没有可展示广告的页面 |
| `AD_LOAD_TIMEOUT` | 单个广告位在 `loadTimeoutMs` 内未完成素材加载 |
| `AD_LOAD_FAILED` | 穿山甲返回加载失败或无填充 |
| `AD_SHOW_FAILED` | 广告素材加载成功但展示失败 |
| `AD_PLAYBACK_FAILED` | 视频播放阶段失败 |
| `REWARD_INVALID` | 激励奖励校验未通过 |

`slotIds` 会按顺序尝试。只有展示前加载失败或超时才会切换到下一个广告位；广告一旦展示，即使之后播放失败也不会再弹出备用广告。开屏、激励视频和新插屏共用全屏互斥，同一时间只能执行一个请求。

## 从 legacy 全屏 API 迁移

旧 API 仍然可用，但新代码应迁移到 v2：

| legacy | v2 |
| --- | --- |
| `startRewardVideo({ codeid })` | `createAdRequest({ format: 'rewarded' })` + `showRewardedAd` |
| `startInterstitialAd({ codeid })` | `createAdRequest({ format: 'interstitial' })` + `showInterstitialAd` |
| `startFullScreenVideo({ codeid })` | `showInterstitialAd`，穿山甲已将原全屏视频合并为新插屏 |
| `subscribe(...)` + `cleanup()` | `onEvent`，Promise 完成后自动移除原生监听 |

legacy 调用仍返回 `{ result, subscribe, cleanup }`，并通过统一 v2 控制器执行；已有业务可以渐进迁移。

## Draw 信息流（Android）

Draw 信息流当前仅支持 Android。

```tsx
import {
  DrawFeedView,
  loadDrawFeedAd,
} from '@24jieqi/react-native-brayant-ad';

loadDrawFeedAd({
  appid: '你的穿山甲 appid',
  codeid: '你的 Draw 广告位',
});

<DrawFeedView
  appid="你的穿山甲 appid"
  codeid="你的 Draw 广告位"
  visible={true}
  onAdShow={(event) => {
    console.log('Draw 展示', event);
  }}
  onAdClick={(event) => {
    console.log('Draw 点击', event);
  }}
  onAdError={(event) => {
    console.log('Draw 失败', event);
  }}
/>;
```

## 兼容 API

重构后仍保留旧 API，方便已有项目迁移。新项目建议优先使用 v2 API。

### `init`

旧版初始化方法，参数名使用 `appid`。

```tsx
import { init } from '@24jieqi/react-native-brayant-ad';

await init({
  appid: '你的穿山甲 appid',
  app: '你的应用名',
  uid: '用户 ID',
  amount: 1000,
  reward: '金币',
  debug: __DEV__,
});
```

### `FeedAdView`

旧版 Feed 组件直接传 `codeid`。

```tsx
import { FeedAdView, legacy } from '@24jieqi/react-native-brayant-ad';

await legacy.preloadFeedAd({
  codeid: '你的 Feed 广告位',
  adWidth: 375,
});

<FeedAdView
  codeid="你的 Feed 广告位"
  adWidth={375}
  visible={true}
  onAdLayout={(event) => {
    console.log('Feed 渲染完成', event);
  }}
  onAdClose={(event) => {
    console.log('Feed 关闭', event);
  }}
  onAdError={(event) => {
    console.log('Feed 失败', event);
  }}
  onAdClick={(event) => {
    console.log('Feed 点击', event);
  }}
/>;
```

### `BannerAdView`

旧版 Banner 组件直接传 `codeid`。

```tsx
import { BannerAdView } from '@24jieqi/react-native-brayant-ad';

<BannerAdView
  codeid="你的 Banner 广告位"
  adWidth={320}
  adHeight={50}
  visible={true}
  onAdRenderSuccess={(event) => {
    console.log('Banner 渲染成功', event);
  }}
  onAdDismiss={(event) => {
    console.log('Banner 关闭', event);
  }}
  onAdError={(event) => {
    console.log('Banner 失败', event);
  }}
  onAdClick={(event) => {
    console.log('Banner 点击', event);
  }}
/>;
```

### 旧版开屏广告

如果你的项目已经接入 `dyLoadSplashAd`、`legacy.preloadSplashAd`、`hasPreloadedSplashAd`，可以继续使用。

```tsx
import {
  dyLoadSplashAd,
  hasPreloadedSplashAd,
  legacy,
} from '@24jieqi/react-native-brayant-ad';

await legacy.preloadSplashAd({ codeid: '你的开屏广告位' });

const state = await hasPreloadedSplashAd();
if (state.hasAd) {
  const splash = dyLoadSplashAd({
    codeid: '你的开屏广告位',
    anim: 'default',
  });

  splash.subscribe('onAdClose', () => {
    console.log('开屏关闭');
  });

  try {
    await splash.result;
  } finally {
    splash.cleanup();
  }
}
```

旧版开屏事件：

| 事件 | 说明 |
| --- | --- |
| `onAdError` | 广告加载失败 |
| `onAdClick` | 广告点击 |
| `onAdClose` | 广告关闭 |
| `onAdSkip` | 用户跳过 |
| `onAdShow` | 广告开始展示 |
| `onPreloadSuccess` | 预加载成功 |
| `onPreloadFail` | 预加载失败 |

## 导出总览

```ts
export {
  initializeAdSdk,
  createAdRequest,
  preloadFeedAd,
  preloadBannerAd,
  preloadSplashAd,
  preloadRewardedAd,
  preloadInterstitialAd,
  showSplashAd,
  showRewardedAd,
  showInterstitialAd,
  FeedAd,
  BannerAd,
  requestPermission,
  startRewardVideo,
  startFullScreenVideo,
  startInterstitialAd,
  DrawFeedView,
  loadDrawFeedAd,
  init,
  loadFeedAd,
  FeedAdView,
  BannerAdView,
  dyLoadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
  multiply,
  legacy,
};
```

类型导出：

```ts
export type {
  AdError,
  AdEvent,
  AdEventAction,
  AdFormat,
  AdLifecycleState,
  AdPreloadToken,
  AdRequest,
  AdSdkConfig,
  AdSdkInitResult,
  AdSize,
  AdTerminalStatus,
  FullscreenAdResult,
  FullscreenAdParams,
  InlineAdProps,
  InterstitialAdRequest,
  InterstitialAdResult,
  RewardedAdOptions,
  RewardedAdRequest,
  RewardedAdResult,
  RewardVerification,
};
```

## 推荐接入顺序

1. 完成 Android Maven 仓库或 iOS Pods 配置。
2. 在业务确认隐私授权后调用 `initializeAdSdk({ allowInitialization: true })`。
3. 调用 `requestPermission()` 处理广告 SDK 权限或 ATT。
4. 使用 `createAdRequest` 为每个广告场景创建请求。
5. 对 Feed、Banner、Splash、激励和新插屏按场景调用对应 `preload*` 方法。
6. 使用组件或 `show*` 方法消费预加载令牌；不预加载时会实时请求。
7. 激励视频只依据 `result.reward.valid` 发奖，并记录失败或无效结果。

## 常见问题

### 报错：包未正确链接

确认已经重新构建原生应用：

```bash
cd ios && pod install
cd ..
npx react-native run-ios
# 或
npx react-native run-android
```

不要在 Expo Go 中使用本库。

### v2 的 `preloadFeedAd` 和旧版 `preloadFeedAd` 有什么区别？

顶层导出的 `preloadFeedAd` 是 v2 方法，参数必须是 `AdRequest`。

旧版方法在 `legacy.preloadFeedAd` 中，参数是 `{ codeid, adWidth }`。

```tsx
// v2
await preloadFeedAd(
  createAdRequest({ format: 'feed', slotIds: ['id'], scene: 'home' })
);

// legacy
await legacy.preloadFeedAd({ codeid: 'id', adWidth: 375 });
```

### 为什么 Feed 或 Banner 会切换广告位？

`slotIds` 是候选广告位列表。组件收到当前广告位的终态错误事件后，会按顺序尝试下一个广告位。这样可以在主广告位无填充时自动回退到备用广告位。

### 什么时候需要手动传 `preloadToken`？

如果你希望明确控制某次展示使用哪次预加载结果，可以把 `preload*` 返回的 token 传给组件或 `show*`。如果不传，v2 会自动领取同规格的未消费令牌。

### 激励视频关闭了，为什么没有奖励？

关闭、播放完成和奖励校验互相独立。只有 `result.reward?.valid === true` 才表示穿山甲确认本次奖励有效；用户跳过、服务端验证失败或未达到奖励条件时都不应发奖。

### 为什么返回 `FULLSCREEN_BUSY`？

开屏、激励和新插屏都需要占用系统全屏展示能力。已有请求未结束时，新请求会返回 `status: 'cancelled'` 和 `FULLSCREEN_BUSY`，业务应等待当前广告结束后再触发。

### 为什么返回 `AD_LOAD_FAILED` 或一直没有填充？

确认代码位类型与 API 匹配：激励代码位只能用于 `rewarded`，穿山甲“新插屏”代码位用于 `interstitial`。同时检查 App ID、包名、测试设备、代码位生效状态和网络；原生错误码会保留在 `error.nativeCode`。

### 为什么返回页面不可用？

广告必须在 React Native 页面已经挂载且 App 处于前台时展示。Android 没有当前 Activity 时返回 `ACTIVITY_UNAVAILABLE`，iOS 找不到可展示控制器时返回 `VIEW_CONTROLLER_UNAVAILABLE`。

### Draw 信息流能在 iOS 使用吗？

不能。`DrawFeedView` 和 `loadDrawFeedAd` 当前只建议在 Android 使用。

## 本地开发

```bash
pnpm install
pnpm typecheck
pnpm test
pnpm lint
pnpm prepare
```

修改 `src/` 后必须运行：

```bash
pnpm prepare
```

因为库产物由 `react-native-builder-bob` 生成到 `lib/`。

示例应用：

```bash
pnpm example start

# 另一个终端
cd example
pnpm android
# 或
pnpm ios
```
