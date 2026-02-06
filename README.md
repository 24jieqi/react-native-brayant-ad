# react-native-brayant-ad

React Native 国内广告 SDK 封装，当前主要集成穿山甲（Pangle），支持以下能力：

- 开屏广告（支持预加载）
- 激励视频
- 全屏视频
- 信息流 Feed（组件）
- Draw 信息流（组件）
- Banner（组件）

## 1. 安装

```bash
pnpm add @24jieqi/react-native-brayant-ad
# 或
npm i @24jieqi/react-native-brayant-ad
# 或
yarn add @24jieqi/react-native-brayant-ad
```

### iOS

安装依赖后执行：

```bash
cd ios && pod install
```

## 2. 原生配置

### 2.1 Android 仓库配置（必须）

在宿主 App 的 `android/build.gradle`（或你项目的统一仓库配置处）确保包含：

```groovy
allprojects {
  repositories {
    google()
    mavenCentral()
    maven { url 'https://artifact.bytedance.com/repository/pangle' }
  }
}
```

### 2.2 iOS 隐私权限（建议）

如果你计划在 iOS 调用 `requestPermission()` 请求 ATT，请在 `Info.plist` 配置 `NSUserTrackingUsageDescription`。

## 3. 能力与平台支持

| 能力 | 导出名 | Android | iOS |
| --- | --- | --- | --- |
| SDK 初始化 | `init` | ✅ | ✅ |
| ATT/权限请求 | `requestPermission` | ✅（Android 权限） | ✅（ATT） |
| 开屏广告 | `dyLoadSplashAd` | ✅ | ✅ |
| 开屏预加载 | `preloadSplashAd` / `hasPreloadedSplashAd` / `clearPreloadedSplashAd` | ✅ | ✅（兼容实现） |
| 激励视频 | `startRewardVideo` | ✅ | ✅ |
| 全屏视频 | `startFullScreenVideo` | ✅ | ✅ |
| Feed 信息流组件 | `FeedAdView` | ✅ | ✅ |
| Draw 信息流组件 | `DrawFeedView` / `loadDrawFeedAd` | ✅ | ❌ |
| Banner 组件 | `BannerAdView` | ✅ | ✅ |

## 4. 快速开始（推荐接入顺序）

### 4.1 初始化 SDK

建议在 App 启动时调用一次：

```tsx
import { init } from '@24jieqi/react-native-brayant-ad';

await init({
  appid: '你的穿山甲 appid',
  app: '你的应用名',
  uid: '可选用户ID',
  amount: 1000,
  reward: '金币',
  debug: false,
});
```

`init` 参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `appid` | `string` | 是 | 穿山甲应用 ID |
| `app` | `string` | 否 | 应用名 |
| `uid` | `string` | 否 | 业务侧用户标识 |
| `amount` | `number` | 否 | 激励数量 |
| `reward` | `string` | 否 | 激励名称 |
| `debug` | `boolean` | 否 | 调试模式 |

### 4.2 请求权限（按需）

```tsx
import { requestPermission } from '@24jieqi/react-native-brayant-ad';

requestPermission();
```

- Android：请求相关权限
- iOS：请求 ATT

## 5. 开屏广告

### 5.1 API

```tsx
import {
  dyLoadSplashAd,
  preloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
} from '@24jieqi/react-native-brayant-ad';
```

`dyLoadSplashAd({ codeid, anim? })`

- `codeid: string` 必填
- `anim?: 'default' | 'none' | 'catalyst' | 'slide' | 'fade'`

返回对象：

- `result`: Promise
- `subscribe(type, callback)`: 订阅事件
- `cleanup()`: 移除当前实例所有监听

事件类型：

- `onAdError`
- `onAdClick`
- `onAdClose`
- `onAdSkip`
- `onAdShow`
- `onPreloadSuccess`
- `onPreloadFail`

### 5.2 推荐：启动时预加载（尤其 Android）

```tsx
await preloadSplashAd({ codeid: '你的开屏广告位' });

const { hasAd, status } = await hasPreloadedSplashAd();
// hasAd: 是否可直接展示
// status: 预加载状态码

if (hasAd) {
  const splash = dyLoadSplashAd({ codeid: '你的开屏广告位' });
  splash.subscribe('onAdClose', () => {});
}
```

不再使用时可清理缓存：

```tsx
clearPreloadedSplashAd();
```

## 6. 激励视频

```tsx
import { startRewardVideo } from '@24jieqi/react-native-brayant-ad';

const reward = startRewardVideo({ codeid: '你的激励广告位' });

reward.result.then((res) => {
  console.log('激励视频结果', res);
});

reward.subscribe('onAdLoaded', (e) => console.log('加载成功', e));
reward.subscribe('onAdError', (e) => console.log('加载失败', e));
reward.subscribe('onAdClick', (e) => console.log('点击', e));
reward.subscribe('onAdClose', (e) => console.log('关闭', e));

// 页面销毁时
reward.cleanup();
```

支持事件：`onAdError`、`onAdLoaded`、`onAdClick`、`onAdClose`。

## 7. 全屏视频

```tsx
import { startFullScreenVideo } from '@24jieqi/react-native-brayant-ad';

const full = startFullScreenVideo({
  codeid: '你的全屏广告位',
  orientation: 'VERTICAL', // 可选：HORIZONTAL | VERTICAL
  provider: '头条', // 可选：头条 | 腾讯 | 快手（主要 Android 使用）
});

full.result.then((res) => {
  console.log('全屏视频结果', res);
});

full.subscribe('onAdLoaded', () => {});
full.subscribe('onAdError', () => {});
full.subscribe('onAdClick', () => {});
full.subscribe('onAdClose', () => {});

// 页面销毁时
full.cleanup();
```

## 8. Feed 信息流组件

```tsx
import { FeedAdView, preloadFeedAd } from '@24jieqi/react-native-brayant-ad';

await preloadFeedAd({ codeid: '你的Feed广告位', adWidth: 375 });

<FeedAdView
  codeid="你的Feed广告位"
  adWidth={375}
  visible={true}
  onAdLayout={(e) => console.log('渲染成功', e)}
  onAdError={(e) => console.log('加载失败', e)}
  onAdClick={(e) => console.log('点击', e)}
  onAdClose={(e) => console.log('关闭', e)}
/>
```

`FeedAdView` 主要参数：

- `codeid: string`（必填）
- `adWidth?: number`
- `visible?: boolean`
- `style?: ViewStyle`
- `onAdLayout/onAdError/onAdClick/onAdClose`

## 9. Draw 信息流组件（Android）

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
  onAdShow={(e) => console.log('展示', e)}
  onAdClick={(e) => console.log('点击', e)}
  onAdError={(e) => console.log('错误', e)}
/>
```

## 10. Banner 组件（Android / iOS）

```tsx
import { BannerAdView } from '@24jieqi/react-native-brayant-ad';

<BannerAdView
  codeid="你的 Banner 广告位"
  adWidth={320}
  adHeight={50}
  visible={true}
  onAdRenderSuccess={(e) => console.log('渲染成功', e)}
  onAdError={(e) => console.log('加载失败', e)}
  onAdShow={(e) => console.log('展示', e)}
  onAdClick={(e) => console.log('点击', e)}
  onAdDismiss={(e) => console.log('关闭', e)}
  onAdDislike={(e) => console.log('不感兴趣', e)}
/>
```

说明：

- Android / iOS 均可使用同一套 `BannerAdView` 参数。
- iOS 端不触发 `onAdDislike`（该事件主要用于 Android）。

## 11. 导出清单

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
  loadDrawFeedAd,
  DrawFeedView,
  FeedAdView,
  BannerAdView,
} from '@24jieqi/react-native-brayant-ad';
```

## 12. 常见问题

### 12.1 提示模块未链接（`doesn't seem to be linked`）

- 确认已重新编译 App（不是仅热更新）
- iOS 确认执行过 `pod install`
- 确认不是在 Expo Go 中运行

### 12.2 Android 开屏后出现白屏

优先使用 `preloadSplashAd` 在启动后预加载，再用 `dyLoadSplashAd` 展示。

### 12.3 监听器重复触发

每次创建广告实例后，在页面卸载时调用 `cleanup()`，并避免同一实例重复绑定同一事件。

## 13. 本地开发

```bash
pnpm typecheck
pnpm lint
pnpm test
pnpm prepare
```

如果你修改了库源码（`src/`），请先执行：

```bash
pnpm prepare
```

然后再运行示例工程。
