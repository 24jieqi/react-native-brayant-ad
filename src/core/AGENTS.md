# src/core/ — v2 API 核心模块

## 概览

v1.1.7 引入的声明式广告请求层。与 `src/dy/api/`（v1 命令式 API）并列，不互通。物料构建由 `react-native-builder-bob` 打包到 `lib/`。

## 文件职责

| 文件 | 只读 | 说明 |
|------|------|------|
| `types.ts` | ✅ | 所有公共类型定义（`AdRequest`, `AdEvent`, `AdPreloadToken`, `InlineAdProps` 等） |
| `request.ts` | ✅ | `createAdRequest()` 工厂，含 `slotIds` 去重和合法性校验 |
| `native.ts` | ✅ | 原生模块桥接，iOS → `PangleAdModule`，Android → `AdManager` |
| `sdk.ts` | | `initializeAdSdk()` 防重复初始化，`allowInitialization` 开关 |
| `preload.ts` | | Feed、Banner、开屏、激励、新插屏的预加载管理 |
| `fullscreen-lock.ts` | | 开屏、激励、新插屏共享的全屏请求互斥锁 |
| `fullscreen.ts` | | 激励和新插屏的统一展示、候选回退与事件订阅 |
| `rewarded.ts` / `interstitial.ts` | | 强类型公开展示入口 |
| `splash.ts` | | `showSplashAd()` 开屏控制器，共享全屏互斥 + 超时 + 事件订阅 |
| `candidates.ts` | | 候选广告位切换（`resolveAdSlotIds`, `shouldTryNextCandidate`） |
| `state-machine.ts` | | `AdLifecycle` 状态机 + `FullscreenSettlement` 一次结算 |

## 依赖方向

```
types.ts ← request.ts, native.ts ← preload.ts, fullscreen.ts, splash.ts
                                      ↑              ↑
                              candidates.ts   fullscreen-lock.ts
```

`src/component/`（v2 组件）依赖此模块；`src/dy/`（v1）不依赖。

## 关键约束

- 新增广告类型时：`types.ts` 加类型 → `request.ts` 加工厂分支 → `preload.ts` 加导出函数 → `native.ts` 加桥接方法
- 激励与新插屏由 `fullscreen.ts` 统一处理；只允许在展示前失败时切换候选广告位
- `preload.ts` 内部 `preloadTasks` / `preloadedTokens` 两个 Map 全局共享，单元测试后必须调用 `resetPreloadTokensForTests()`
- core 模块不改 `src/dy/` 中的代码，反之亦然
