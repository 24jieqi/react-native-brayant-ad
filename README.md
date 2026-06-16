# react-native-brayant-ad

`@24jieqi/react-native-brayant-ad` 是 React Native 国内广告 SDK 封装，当前主要接入穿山甲（Pangle / Ads-CN）。库内已经重构出一套 v2 API，用统一的 `AdRequest` 描述广告请求，支持初始化防重复、候选广告位、预加载令牌和统一事件流。

- 当前版本：`1.1.7`
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
| 激励视频 | `startRewardVideo` | 支持 | 兼容实现 | iOS 当前复用插屏链路 |
| 全屏视频 | `startFullScreenVideo` | 支持 | 兼容实现 | iOS 当前复用插屏链路 |
| 插屏广告 | `startInterstitialAd` | 支持 | 支持 | Android 当前复用全屏视频通道 |
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

`preloadFeedAd`、`preloadBannerAd`、`preloadSplashAd` 会返回 `AdPreloadToken`。组件或 `showSplashAd` 会优先消费同规格令牌。

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
- 如果已有开屏正在执行，后续请求会返回 `status: 'cancelled'`，错误码为 `SPLASH_BUSY`。
- `request.format` 不是 `splash` 时会抛出错误。

## 命令式广告：激励、全屏、插屏

激励视频、全屏视频、插屏广告目前仍使用 legacy 命令式 API。调用后会得到一个广告实例，包含：

| 字段 | 说明 |
| --- | --- |
| `result` | 原生展示 Promise |
| `subscribe(type, callback)` | 订阅事件 |
| `cleanup()` | 移除当前实例注册的监听 |

使用完成后必须调用 `cleanup()`。

```tsx
import { startRewardVideo } from '@24jieqi/react-native-brayant-ad';

const reward = startRewardVideo({
  codeid: '你的激励视频广告位',
});

reward.subscribe('onAdLoaded', () => {
  console.log('激励视频加载成功');
});

reward.subscribe('onAdClose', () => {
  console.log('激励视频关闭');
});

reward.subscribe('onAdError', (error) => {
  console.log('激励视频失败', error);
});

try {
  await reward.result;
} finally {
  reward.cleanup();
}
```

全屏视频：

```tsx
import { startFullScreenVideo } from '@24jieqi/react-native-brayant-ad';

const fullScreen = startFullScreenVideo({
  codeid: '你的全屏视频广告位',
  orientation: 'VERTICAL',
  provider: '头条',
});
```

插屏广告：

```tsx
import { startInterstitialAd } from '@24jieqi/react-native-brayant-ad';

const interstitial = startInterstitialAd({
  codeid: '你的插屏广告位',
  orientation: 'VERTICAL',
  provider: '头条',
});
```

支持事件：

| 事件 | 说明 |
| --- | --- |
| `onAdLoaded` | 广告加载成功 |
| `onAdError` | 广告加载或展示失败 |
| `onAdClick` | 用户点击广告 |
| `onAdClose` | 广告关闭 |

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
  showSplashAd,
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
  AdFormat,
  AdLifecycleState,
  AdPreloadToken,
  AdRequest,
  AdSdkConfig,
  AdSdkInitResult,
  AdSize,
  AdTerminalStatus,
  FullscreenAdResult,
  InlineAdProps,
};
```

## 推荐接入顺序

1. 完成 Android Maven 仓库或 iOS Pods 配置。
2. 在业务确认隐私授权后调用 `initializeAdSdk({ allowInitialization: true })`。
3. 调用 `requestPermission()` 处理广告 SDK 权限或 ATT。
4. 使用 `createAdRequest` 为每个广告场景创建请求。
5. 对 Feed、Banner、Splash 优先调用对应 `preload*` 方法。
6. 使用 `FeedAd`、`BannerAd` 或 `showSplashAd` 消费预加载令牌。
7. 对激励、全屏、插屏这类命令式广告，在 `finally` 中调用 `cleanup()`。

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

如果你希望明确控制某次渲染使用哪次预加载结果，可以把 `preload*` 返回的 token 传给组件或 `showSplashAd`。如果不传，v2 会自动领取同规格的未消费令牌。

### iOS 上激励视频为什么看起来像插屏？

当前 iOS 的 `startRewardVideo` 和 `startFullScreenVideo` 复用 `PangleAdModule` 的插屏加载和展示链路。这是兼容实现，不等同于完整激励视频能力。

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
