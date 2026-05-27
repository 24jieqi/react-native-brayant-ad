# react-native-brayant-ad Agent 指南

本文档使用渐进式披露：先读“必须遵守”和“常用命令”，开始工作；只有在涉及对应代码时，再展开后续细节。

## 0. 必须遵守

- 所有对话、提交说明、文档和注释默认使用中文。
- 修改 `src/` 后必须运行 `pnpm prepare`，因为库产物由 `react-native-builder-bob` 生成到 `lib/`。
- 不要用 `as any`、`@ts-ignore`、`@ts-expect-error` 压制类型错误；先修正类型设计。
- TypeScript 启用严格模式和 `verbatimModuleSyntax`，类型导入必须写成 `import type`。
- 调用原生模块或原生组件前，必须保留未链接时的 `LINKING_ERROR` 检查模式。
- 平台差异必须显式判断，尤其是仅 Android 可用的广告能力。
- 事件监听要复用现有 listener cache 模式，避免同一事件重复订阅。

## 1. 常用命令

优先使用 `pnpm` 脚本；只有需要排查脚本本身时才直接调用底层命令。

```bash
# 类型检查
pnpm typecheck

# Lint
pnpm lint

# 测试
pnpm test
jest src/__tests__/index.test.tsx

# 构建库产物
pnpm prepare
pnpm clean

# 示例应用
pnpm example
pnpm example start
```

## 2. 修改代码时的最小流程

1. 先定位影响范围：公共 API 看 `src/index.tsx`，广告 API 看 `src/dy/api/`，视图组件看 `src/dy/component/`。
2. 保持现有导入、命名、事件和平台判断模式。
3. 修改 `src/` 后运行 `pnpm prepare`。
4. 至少运行 `pnpm typecheck`；涉及行为变更时再运行 `pnpm test` 和 `pnpm lint`。
5. 需要手动验证时，启动示例应用并在模拟器或真机中重载。

## 3. 项目结构速览

```text
src/
├── index.tsx                    # 主入口，导出公共 API
├── dy/
│   ├── api/                     # 各广告类型 API
│   │   ├── AdManager.ts         # 初始化、权限等核心能力
│   │   ├── SplashAd.ts          # 开屏广告
│   │   ├── RewardVideo.ts       # 激励视频
│   │   ├── FullScreenVideo.ts   # 全屏视频
│   │   └── InterstitialAd.ts    # 插屏广告
│   └── component/               # React Native 原生视图封装
│       ├── BannerAd.tsx
│       ├── FeedAd.tsx
│       └── DrawFeedAd.tsx
└── __tests__/
    └── index.test.tsx
```

示例应用入口通常在 `example/src/App.tsx`，信息流示例在 `example/src/DrawFeedViewDemo.tsx`。

## 4. 代码风格

### 4.1 格式化

Prettier 配置在 `package.json` 中，核心规则：

- 单引号：`'text'`
- 缩进：2 个空格，不使用 tab
- 尾随逗号：ES5 兼容
- `quoteProps`: `consistent`

### 4.2 命名

- 组件：`PascalCase`，如 `FeedAdView`、`DrawFeedAd`
- 函数和变量：`camelCase`，如 `dyLoadSplashAd`、`loadFeedAd`
- 类型和接口：`PascalCase`，如 `FeedAdProps`
- 枚举：沿用现有公开 API 风格，如 `AD_EVENT_TYPE`
- 文件名：组件使用 `PascalCase`，工具和 API 文件沿用现有目录风格

### 4.3 导入和导出

```typescript
import { init } from './dy/api/AdManager';
import type { ViewStyle } from 'react-native';

const { AdManager } = NativeModules;

export { init, loadFeedAd, requestPermission };
export default FeedAdView;
```

## 5. TypeScript 约束

当前项目启用严格类型检查，常见影响：

- `strict`: 所有严格规则生效。
- `verbatimModuleSyntax`: 类型必须通过 `import type` 导入。
- `noUncheckedIndexedAccess`: 索引访问结果可能是 `undefined`。
- `noUnusedLocals` / `noUnusedParameters`: 不保留未使用的变量或参数。
- 模块与目标为 `esnext`，JSX 为 `react`。

公共 props 用 `interface`，内部结构可用 `type`。扩展现有公开类型时，优先保持向后兼容。

```typescript
export interface FeedAdProps {
  codeid: string;
  style?: ViewStyle;
  adWidth?: number;
  visible?: boolean;
  onAdLayout?: Function;
  onAdError?: Function;
  onAdClose?: Function;
  onAdClick?: Function;
}

type ListenerCache = {
  [K in AD_EVENT_TYPE]: EventSubscription | undefined;
};
```

## 6. React Native 组件模式

- 使用函数组件。
- 可选 props 在解构时给默认值，例如 `adWidth = 375`、`visible = true`。
- `visible`、关闭态等条件应早返回 `null`。
- 静态样式使用 `StyleSheet.create`，宽高等动态值可内联组合。
- 回调传出原生事件时，保持 `e.nativeEvent` 语义。

```typescript
const FeedAdView = (props: FeedAdProps) => {
  const { codeid, style, adWidth = 375, visible = true, onAdError } = props;
  const [closed, setClosed] = useState(false);

  if (!visible || closed) return null;

  return (
    <FeedAdComponent
      codeid={codeid}
      style={{ width: adWidth, ...style }}
      onAdError={(e) => {
        onAdError && onAdError(e.nativeEvent);
      }}
    />
  );
};
```

## 7. 原生模块和事件模式

### 7.1 未链接检查

原生组件必须保留 `LINKING_ERROR` 兜底，避免未链接时静默失败。

```typescript
const Component =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<FeedAdProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };
```

### 7.2 事件订阅

原生事件名称使用模块名前缀，例如 `'SplashAd-onAdError'`。新增事件时同步维护枚举、listener cache 和订阅逻辑。

```typescript
const eventEmitter = new NativeEventEmitter(SplashAd);

return {
  result,
  subscribe: (type: AD_EVENT_TYPE, callback: (event: unknown) => void) => {
    if (listenerCache[type]) {
      listenerCache[type]?.remove();
    }

    return (listenerCache[type] = eventEmitter.addListener(
      'SplashAd-' + type,
      callback
    ));
  },
};
```

### 7.3 平台判断

平台专属能力必须显式判断，并保持调用方行为可预期。

```typescript
if (Platform.OS === 'android') {
  return AdManager.loadDrawFeedAd(info);
}
```

## 8. 测试和验证

测试位于 `src/__tests__/`，命名使用 `*.test.ts` 或 `*.test.tsx`。Jest 配置在 `package.json`，会忽略 `example/node_modules` 和 `lib/`。

推荐验证组合：

```bash
# 文档或非代码变更
pnpm typecheck

# src/ 代码变更
pnpm prepare
pnpm typecheck

# 公共 API、事件或平台行为变更
pnpm prepare
pnpm typecheck
pnpm test
pnpm lint
```

## 9. 示例应用调试

首次或原生代码变更后，按平台准备环境：

```bash
# Android：确认设备或模拟器
adb devices

# iOS：安装 Pods
cd example/ios && pod install
```

日常调试流程：

```bash
pnpm prepare
pnpm example start

# 另一个终端中运行平台应用
cd example && pnpm android
cd example && pnpm ios
```

日志查看：

```bash
adb logcat | grep BrayantAd
```

iOS 日志通过 Xcode 控制台查看。

## 10. 常见改动提示

- 新增广告 API：先看 `src/dy/api/` 中同类文件，复用事件枚举、事件前缀、listener cache 和平台判断模式。
- 新增原生视图组件：先看 `FeedAd.tsx`、`DrawFeedAd.tsx`、`BannerAd.tsx`，保留 `requireNativeComponent` 和 `LINKING_ERROR` 结构。
- 修改公共导出：同步检查 `src/index.tsx`、类型声明生成结果和测试。
- 修改示例：确认示例代码仍能覆盖新增或变更的公开能力。
