# react-native-brayant-ad

接入穿山甲SDK

## 后期代办

接入GeoMoreSdk

## 安装

```sh

npm install @24jieqi/react-native-brayant-ad
```

在RN项目的 Project级别的 build.gradle 中添加如下配置 （android/build.gradle）

```groovy
allprojects {
  repositories {
    google()
    mavenCentral()
    // 添加穿山甲SDK仓库
    maven {
      url 'https://artifact.bytedance.com/repository/pangle'
    }
  }
}
```

### Android 完整集成配置

由于本库底层使用穿山甲（Pangle）SDK，需要在 Android 项目中添加以下配置才能正常使用。

#### 添加 Pangle SDK 依赖

在你的 **android/build.gradle** 的 `dependencies` 中添加：

```groovy
dependencies {
    implementation 'com.pangle.cn:ads-sdk-pro:7.3.0.8'
}
```

## 必要配置

在项目入口文件中初始化init, 如果不是全局初始化的就需要在每次调用的时候传入

```js
import { init } from '@24jieqi/react-native-brayant-ad';

useEffect(() => {
  init({
    appid: 'xxxx',
    app: 'app名称',
    amount: 1000,
    reward: '金币',
    debug: true,
  }).then((res) => {});
});
```

### init 方法配置

| 参数   | 说明                            | 类型    | 默认值        | 是否必填 |
| ------ | ------------------------------- | ------- | ------------- | -------- |
| appid  | 穿山甲中创建应用的appid         | string  | -             | 是       |
| app    | app名称                         | string  | 穿山甲媒体APP | 否       |
| uid    | 有些uid和穿山甲商务有合作的需要 | string  | -             | 否       |
| amount | 奖励数量                        | number  | 1000          | 否       |
| reward | 奖励名称                        | string  | 金币          | 否       |
| debug  | 是否是开发者模式                | boolean | false         | 否       |

init 成功会返回一个promise

# 1. 开屏广告

## API

### dyLoadSplashAd

#### 开屏广告事件类型

```ts
interface AD_EVENT_TYPE {
  onAdError: string; // 广告加载失败监听
  onAdClick: string; // 广告被点击监听
  onAdClose: string; // 广告关闭
  onAdSkip: string; // 用户点击跳过广告监听
  onAdShow: string; // 开屏广告开始展示
}

EmuAnim = 'default' | 'none' | 'catalyst' | 'slide' | 'fade';
```

| 参数   | 说明         | 类型    | 默认值  | 是否必填 |
| ------ | ------------ | ------- | ------- | -------- |
| codeid | 广告位id     | string  | -       | 是       |
| anim   | 广告进入方式 | EmuAnim | default | 否       |

### preloadSplashAd (Android 推荐)

**Android 端推荐使用预加载方式，可避免启动页结束后出现白屏。**

在应用启动时（init 之后）预加载开屏广告，展示时直接使用已加载的广告。

```ts
// 预加载开屏广告
await preloadSplashAd({ codeid: 'your_code_id' });

// 展示广告（使用预加载的广告，无白屏）
const splashAd = dyLoadSplashAd({ codeid: 'your_code_id' });
```

| 参数   | 说明     | 类型   | 默认值 | 是否必填 |
| ------ | -------- | ------ | ------ | -------- |
| codeid | 广告位id | string | -      | 是       |

### hasPreloadedSplashAd

检查是否有预加载的广告可用（Android）。

```ts
const { hasAd, status } = await hasPreloadedSplashAd();
// hasAd: boolean - 是否有可用的预加载广告
// status: number - 预加载状态 (0:未加载 1:加载中 2:成功 3:失败)
```

### clearPreloadedSplashAd

清除预加载的广告缓存（Android）。

```ts
clearPreloadedSplashAd();
```

## 如何使用

### 基础用法（实时加载）

> 注意：这种方式在 Android 端可能会出现白屏

```tsx
import { dyLoadSplashAd } from '@24jieqi/react-native-brayant-ad';
import { Text, TouchableOpacity } from 'react-native';

const ScrenPage = () => {
  const onOpenScren = () => {
    const splashAd = dyLoadSplashAd({
      codeid: '****',
      anim: 'default',
    });

    splashAd.subscribe('onAdClose', (event) => {
      console.log('广告关闭', event);
    });

    splashAd.subscribe('onAdSkip', (i) => {
      console.log('用户点击跳过监听', i);
    });

    splashAd.subscribe('onAdError', (e) => {
      console.log('开屏加载失败监听', e);
    });

    splashAd.subscribe('onAdClick', (e) => {
      console.log('开屏被用户点击了', e);
    });

    splashAd.subscribe('onAdShow', (e) => {
      console.log('开屏开始展示', e);
    });
  };

  return (
    <TouchableOpacity onPress={onOpenScren}>
      <Text style={{ textAlign: 'center' }}> 开屏</Text>
    </TouchableOpacity>
  );
};
```

### 推荐用法（预加载 - Android）

**Android 端推荐使用预加载方式，避免启动页到广告之间出现白屏。**

```tsx
import {
  init,
  preloadSplashAd,
  hasPreloadedSplashAd,
  dyLoadSplashAd,
} from '@24jieqi/react-native-brayant-ad';
import { useEffect } from 'react';

const App = () => {
  useEffect(() => {
    const initialize = async () => {
      // 1. 初始化 SDK
      await init({
        appid: 'your_app_id',
        app: '应用名称',
        debug: false,
      });

      // 2. Android: 预加载开屏广告（避免白屏）
      if (Platform.OS === 'android') {
        await preloadSplashAd({ codeid: 'your_splash_code_id' });
        console.log('开屏广告预加载完成');
      }
    };

    initialize();
  }, []);

  // 3. 展示开屏广告（Android使用预加载，iOS实时加载）
  const showSplash = async () => {
    // 检查预加载状态（可选）
    if (Platform.OS === 'android') {
      const { hasAd } = await hasPreloadedSplashAd();
      console.log('是否有预加载广告:', hasAd);
    }

    const splashAd = dyLoadSplashAd({
      codeid: 'your_splash_code_id',
      anim: 'default',
    });

    splashAd.subscribe('onAdShow', (event) => {
      console.log('广告展示', event);
    });

    splashAd.subscribe('onAdClose', (event) => {
      console.log('广告关闭', event);
    });

    splashAd.subscribe('onAdError', (error) => {
      console.log('广告错误', error);
    });
  };

  return (
    // ...
  );
};
```

### 在应用启动时自动展示开屏广告

```tsx
import { init, preloadSplashAd, dyLoadSplashAd } from '@24jieqi/react-native-brayant-ad';
import { hide } from 'react-native-bootsplash';

const SplashAdManager = () => {
  useEffect(() => {
    const showSplashAdOnLaunch = async () => {
      try {
        // 1. 初始化广告 SDK
        await init({ appid: 'your_app_id', app: '应用名称' });

        // 2. Android: 预加载广告
        if (Platform.OS === 'android') {
          await preloadSplashAd({ codeid: 'your_splash_code_id' });
        }

        // 3. 展示广告（Android使用预加载，无白屏）
        const splashAd = dyLoadSplashAd({
          codeid: 'your_splash_code_id',
          anim: 'fade',
        });

        splashAd.subscribe('onAdShow', () => {
          console.log('广告展示');
          // Android: 此时可以隐藏启动页（广告已准备好）
          hide({ fade: true });
        });

        splashAd.subscribe('onAdClose', () => {
          console.log('广告关闭');
        });

        splashAd.subscribe('onAdError', (error) => {
          console.log('广告加载失败', error);
          // 出错时也要隐藏启动页
          hide({ fade: true });
        });
      } catch (error) {
        console.error('广告初始化失败:', error);
        hide({ fade: true });
      }
    };

    showSplashAdOnLaunch();
  }, []);

  return null;
};
```

# 2. 激励视频

## API

### requestPermission

> 主动看激励视频时，才检查这个权限

无参数 `requestPermission()`

### startRewardVideo 方法参数

> 开始看激励视频

## API

| 参数   | 说明     | 类型   | 默认值 | 是否必填 |
| ------ | -------- | ------ | ------ | -------- |
| codeid | 广告位id | string | -      | 是       |

#### 激励视频事件类型

```ts
export enum AD_EVENT_TYPE {
  onAdError = 'onAdError', // 广告加载失败监听
  onAdLoaded = 'onAdLoaded', // 广告加载成功监听
  onAdClick = 'onAdClick', // 广告被点击监听
  onAdClose = 'onAdClose', // 广告关闭监听
}
```

## 如何使用

> 这边案列默认全部init初始化后

```tsx
import {
  requestPermission,
  startRewardVideo,
} from '@24jieqi/react-native-brayant-ad';
import { Text, TouchableOpacity } from 'react-native';

const RewardVideoPage = () => {
  const onStartRewardVideo = () => {
    const rewardVideo = startRewardVideo({
      codeid: '****',
    });

    rewardVideo.result.then((val: any) => {
      console.log('RewardVideo 回调结果', val);
    });

    rewardVideo.subscribe('onAdLoaded', (event) => {
      console.log('广告加载成功监听', event);
    });

    rewardVideo.subscribe('onAdError', (event) => {
      console.log('广告加载失败监听', event);
    });

    rewardVideo.subscribe('onAdClose', (event) => {
      console.log('广告被关闭监听', event);
    });

    rewardVideo.subscribe('onAdClick', (event) => {
      console.log('广告点击查看详情监听', event);
    });
  };

  return (
    <TouchableOpacity onPress={onStartRewardVideo}>
      <Text style={{ textAlign: 'center' }}> 激励视频</Text>
    </TouchableOpacity>
  );
};
```

# 3. 全屏视频广告

## api

### startFullScreenVideo 方法参数

| 参数        | 说明     | 类型                       | 默认值   | 是否必填 |
| ----------- | -------- | -------------------------- | -------- | -------- | --- | --- |
| codeid      | 广告位id | string                     | -        | 是       |
| orientation | 竖屏横屏 | 'HORIZONTAL' \| 'VERTICAL' | VERTICAL | 否       | -   | 是  |

## 使用

```tsx
import {
  requestPermission,
  startFullScreenVideo,
} from '@24jieqi/react-native-brayant-ad';
import { useEffect } from 'react';
import { Text, TouchableOpacity } from 'react-native';

const RewardVideoPage = () => {
  useEffect(() => {
    // step 1: 获取权限
    requestPermission();
  }, []);

  return (
    <TouchableOpacity
      style={{
        marginVertical: 20,
        paddingHorizontal: 30,
        paddingVertical: 15,
        backgroundColor: '#F96',
        borderRadius: 50,
      }}
      onPress={() => {
        let fullVideo = startFullScreenVideo({
          codeid: '****',
        });
        console.log('FullVideoAd rs:', fullVideo);
        fullVideo.result?.then((val: any) => {
          console.log('FullVideoAd rs then val', val);
        });

        fullVideo.subscribe('onAdLoaded' as any, (event) => {
          console.log('广告加载成功监听', event);
        });

        fullVideo.subscribe('onAdError' as any, (event) => {
          console.log('广告加载失败监听', event);
        });

        fullVideo.subscribe('onAdClose' as any, (event) => {
          console.log('广告被关闭监听', event);
        });

        fullVideo.subscribe('onAdClick' as any, (event) => {
          console.log('广告点击查看详情监听', event);
        });
      }}
    >
      <Text style={{ textAlign: 'center' }}> Start 全屏视频广告</Text>
    </TouchableOpacity>
  );
};
```

# 4. Draw广告

## api

### loadDrawFeedAd 方法参数

| 参数   | 说明     | 类型   | 默认值 | 是否必填 |
| ------ | -------- | ------ | ------ | -------- | --- | --- |
| codeid | 广告位id | string | -      | 是       |
| appid  | 应用id   | string | -      | 是       | -   | 是  |

## 组件

### DrawFeedView

| 参数      | 说明               | 类型      | 默认值 | 是否必填 |
| --------- | ------------------ | --------- | ------ | -------- |
| codeid    | 广告位id           | string    | -      | 是       |
| appid     | 应用id             | string    | -      | 是       |
| visible   | 是否显示组件中广告 | boolean   | -      | 否       |
| appid     | 应用id             | string    | -      | 是       |
| style     | 组件样式           | ViewStyle | -      | 否       |
| onAdError | 广告错误事件       | Function  | -      | 否       |
| onAdShow  | 显示广告事件       | Function  | -      | 否       |
| onAdClick | 点击广告事件       | Function  | -      | 否       |

## 使用

```tsx
import { loadDrawFeedAd, DrawFeedView } from '@24jieqi/react-native-brayant-ad';
import { useEffect } from 'react';

const RewardVideoPage = () => {
  useEffect(() => {
    loadDrawFeedAd({
      appid: '****',
      codeid: '****',
    });
  }, []);

  return (
    <DrawFeedView
      codeid={'****'}
      appid={'****'}
      visible={true}
      onAdError={(e: any) => {
        console.log('DrawFeedAd 加载失败', e);
      }}
      onAdShow={(e: any) => {
        console.log('DrawFeedAd 开屏开始展示', e);
      }}
      onAdClick={(e: any) => {
        console.log('onAdClick DrawFeed', e.nativeEvent);
      }}
    />
  );
};
```

# 5. Banner广告

> 注意：Banner广告目前仅支持Android平台

## API

### preloadBannerAd

预加载 Banner 广告（Android 专用）

在组件渲染前调用，提前加载广告数据，减少白屏时间。预加载的广告会缓存 5 分钟，过期后自动失效。

| 参数     | 说明         | 类型   | 默认值 | 是否必填 |
| -------- | ------------ | ------ | ------ | -------- |
| codeid   | 广告位 ID    | string | -      | 是       |
| adWidth  | 广告宽度(dp) | number | 320    | 否       |
| adHeight | 广告高度(dp) | number | 50     | 否       |

```tsx
import { NativeModules } from 'react-native';
const { BannerAdModule } = NativeModules;

// 在页面进入前预加载
useEffect(() => {
  BannerAdModule.preloadBannerAd({
    codeid: 'your_codeid',
    adWidth: 320,
    adHeight: 50,
  });
}, []);
```

### hasPreloadedBannerAd

检查是否有预加载的 Banner 广告

```tsx
const hasCache = await BannerAdModule.hasPreloadedBannerAd('your_codeid');
```

### clearPreloadedBannerAd

清除预加载的 Banner 广告缓存

```tsx
BannerAdModule.clearPreloadedBannerAd();
```

## 组件

### BannerAdView

| 参数              | 说明               | 类型      | 默认值 | 是否必填 |
| ----------------- | ------------------ | --------- | ------ | -------- |
| codeid            | 广告位id           | string    | -      | 是       |
| adWidth           | 广告宽度(dp)       | number    | 320    | 否       |
| adHeight          | 广告高度(dp)       | number    | 50     | 否       |
| visible           | 是否显示组件中广告 | boolean   | -      | 否       |
| style             | 组件样式           | ViewStyle | -      | 否       |
| onAdRenderSuccess | 广告渲染成功事件   | Function  | -      | 否       |
| onAdError         | 广告加载失败事件   | Function  | -      | 否       |
| onAdDismiss       | 广告关闭事件       | Function  | -      | 否       |
| onAdClick         | 广告被用户点击事件 | Function  | -      | 否       |
| onAdShow          | 广告展示事件       | Function  | -      | 否       |
| onAdDislike       | 用户不感兴趣事件   | Function  | -      | 否       |

## 使用

### 基础用法

```tsx
import { BannerAdView, init } from '@24jieqi/react-native-brayant-ad';
import { useEffect, useState } from 'react';
import { View } from 'react-native';

const BannerAdPage = () => {
  const [showBannerView, setShowBannerView] = useState(false);

  useEffect(() => {
    init({
      appid: '****',
      app: '设备信息',
    }).then((res) => {
      setShowBannerView(true);
    });
  }, []);

  return (
    <View>
      <BannerAdView
        codeid={'****'}
        adWidth={320}
        adHeight={50}
        visible={showBannerView}
        onAdRenderSuccess={(data: any) => {
          console.log('Banner 广告渲染成功！', data);
        }}
        onAdError={(err: any) => {
          console.log('Banner 广告加载失败！', err);
        }}
        onAdDismiss={(data: any) => {
          console.log('Banner 广告关闭！', data);
        }}
        onAdClick={(val: any) => {
          console.log('Banner 广告被用户点击！', val);
        }}
        onAdShow={(val: any) => {
          console.log('Banner 广告展示', val);
        }}
        onAdDislike={(val: any) => {
          console.log('Banner 用户不感兴趣', val);
        }}
      />
    </View>
  );
};
```

### 推荐用法（预加载）

```tsx
import { BannerAdView } from '@24jieqi/react-native-brayant-ad';
import { NativeModules } from 'react-native';
import { useEffect, useState } from 'react';
import { View } from 'react-native';

const { BannerAdModule } = NativeModules;

const BannerAdPage = () => {
  const [showBannerView, setShowBannerView] = useState(false);

  useEffect(() => {
    // 先预加载广告，再显示组件
    const preloadAndShow = async () => {
      try {
        await BannerAdModule.preloadBannerAd({
          codeid: 'your_codeid',
          adWidth: 320,
          adHeight: 50,
        });
      } catch (error) {
        console.log('预加载失败', error);
      } finally {
        // 无论预加载成功与否，都显示组件
        setShowBannerView(true);
      }
    };

    preloadAndShow();
  }, []);

  return (
    <View>
      <BannerAdView
        codeid={'your_codeid'}
        adWidth={320}
        adHeight={50}
        visible={showBannerView}
        onAdRenderSuccess={(data: any) => {
          console.log('Banner 广告渲染成功！', data);
        }}
        onAdError={(err: any) => {
          console.log('Banner 广告加载失败！', err);
        }}
      />
    </View>
  );
};
```

# 6. 信息流广告

## API

### preloadFeedAd

预加载信息流广告（Android 专用）

在组件渲染前调用，提前加载广告数据，减少白屏时间。

| 参数    | 说明         | 类型   | 默认值 | 是否必填 |
| ------- | ------------ | ------ | ------ | -------- |
| appid   | 应用 ID      | string | -      | 是       |
| codeid  | 广告位 ID    | string | -      | 是       |
| adWidth | 广告宽度(dp) | string | '280'  | 否       |

```tsx
import { preloadFeedAd } from '@24jieqi/react-native-brayant-ad';

// 在页面进入前预加载
useEffect(() => {
  preloadFeedAd({
    appid: 'your_appid',
    codeid: 'your_codeid',
    adWidth: '375',
  });
}, []);
```

## 组件

### FeedAdView

| 参数       | 说明               | 类型      | 默认值 | 是否必填 |
| ---------- | ------------------ | --------- | ------ | -------- |
| codeid     | 广告位id           | string    | -      | 是       |
| adWidth    | 广告宽度           | number    | 375    | 否       |
| visible    | 是否显示组件中广告 | boolean   | -      | 否       |
| style      | 组件样式           | ViewStyle | -      | 否       |
| onAdLayout | 广告加载成功事件   | Function  | -      | 否       |
| onAdClose  | 广告关闭事件       | Function  | -      | 否       |
| onAdClick  | 广告被用户点击事件 | Function  | -      | 否       |
| onAdError  | 广告加载失败事件   | Function  | -      | 否       |

## 使用

### 基础用法

```tsx
import { FeedAdView } from '@24jieqi/react-native-brayant-ad';
import { useEffect, useState } from 'react';

const RewardVideoPage = () => {
  const [showFeedView, setShowFeedView] = useState(false);

  useEffect(() => {
    setShowFeedView(true);
  }, []);

  return (
    <FeedAdView
      codeid={'****'}
      adWidth={400}
      visible={showFeedView}
      onAdLayout={(data: any) => {
        console.log('Feed 广告加载成功！', data);
      }}
      onAdClose={(data: any) => {
        console.log('Feed 广告关闭！', data);
      }}
      onAdError={(err: any) => {
        console.log('Feed 广告加载失败！', err);
      }}
      onAdClick={(val: any) => {
        console.log('Feed 广告被用户点击！', val);
      }}
    />
  );
};
```

### 推荐用法（预加载）

```tsx
import { FeedAdView, preloadFeedAd } from '@24jieqi/react-native-brayant-ad';
import { useEffect, useState } from 'react';

const RewardVideoPage = () => {
  const [showFeedView, setShowFeedView] = useState(false);

  // 页面进入时预加载广告
  useEffect(() => {
    preloadFeedAd({
      appid: 'your_appid',
      codeid: 'your_codeid',
    }).then(() => {
      // 预加载成功后显示组件
      setShowFeedView(true);
    });
  }, []);

  return (
    <FeedAdView
      codeid={'your_codeid'}
      adWidth={375}
      visible={showFeedView}
      onAdLayout={(data: any) => {
        console.log('Feed 广告加载成功！', data);
      }}
      onAdError={(err: any) => {
        console.log('Feed 广告加载失败！', err);
      }}
    />
  );
};
```

### 在列表中使用不同广告位 ID

当需要在列表中展示不同位置的广告时，可以通过传入不同的 `adId` 来实现（组件内部会根据 `adId` 自动映射到对应的广告位）：

```tsx
import { FeedAdView } from '@24jieqi/react-native-brayant-ad';
import { FlatList, View, Text } from 'react-native';

// 定义广告位池配置（可选，用于实现广告位轮询）
const AD_SLOT_POOL = [
  'your_codeid_1', // 第5位广告
  'your_codeid_2', // 第10位广告
];

// 根据 adId 选择广告位（实现轮询逻辑）
const getSlotIdByAdId = (adId: string): string => {
  const index = adId
    .split('')
    .reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return AD_SLOT_POOL[index % AD_SLOT_POOL.length];
};

const ListPage = () => {
  const renderItem = ({ item, index }: { item: any; index: number }) => {
    // 在第5位和第10位插入广告
    if (index === 5 || index === 10) {
      // 生成唯一的 adId，例如：ad_5_1707123456789
      const adId = `ad_${index}_${Date.now()}`;

      return (
        <>
          {/* 正常列表项 */}
          <View style={{ padding: 16 }}>
            <Text>{item.title}</Text>
          </View>
          {/* 广告组件 - 使用 adId 作为唯一标识 */}
          <FeedAdView
            key={adId}  // 强制重新创建组件实例
            codeid={getSlotIdByAdId(adId)}
            adWidth={375}
            visible={true}
            onAdLayout={(data: any) => {
              console.log(`位置 ${index} 广告加载成功！`, data);
            }}
            onAdError={(err: any) => {
              console.log(`位置 ${index} 广告加载失败！`, err);
            }}
          />
        </>
      );
    }

    return (
      <View style={{ padding: 16 }}>
        <Text>{item.title}</Text>
      </View>
    );
  };

  return (
    <FlatList
      data={listData}
      renderItem={renderItem}
      keyExtractor={(item, index) => `item-${index}`}
    />
  );
};
```

#### 封装 NativeAd 组件（推荐用法）

为了更好的开发体验，建议封装一个 `NativeAd` 组件，对外暴露 `adId` 参数：

```tsx
import { FeedAdView, preloadFeedAd } from '@24jieqi/react-native-brayant-ad';
import React, { useEffect, useState } from 'react';
import { View } from 'react-native';

interface NativeAdProps {
  adId: string;        // 唯一广告标识，用于瀑布流场景
  slotID?: string;     // 可选：指定广告位，不传则使用默认或轮询
  style?: ViewStyle;
  onAdLoaded?: Function;
  onAdError?: Function;
  onAdClick?: Function;
  onAdClose?: Function;
}

// 广告位池配置
const AD_SLOT_POOL = [
  'your_codeid_for_position_5',
  'your_codeid_for_position_10',
];

// 根据 adId 选择广告位（实现轮询）
const getSlotIdByAdId = (adId: string): string => {
  const index = adId
    .split('')
    .reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return AD_SLOT_POOL[index % AD_SLOT_POOL.length];
};

export const NativeAd: React.FC<NativeAdProps> = ({
  adId,
  slotID,
  style,
  onAdLoaded,
  onAdError,
  onAdClick,
  onAdClose,
}) => {
  const [isReady, setIsReady] = useState(false);
  const codeid = slotID || getSlotIdByAdId(adId);

  useEffect(() => {
    // 预加载广告
    preloadFeedAd({ appid: 'your_appid', codeid })
      .then(() => setIsReady(true))
      .catch(() => setIsReady(true));
  }, [codeid]);

  if (!isReady) return null;

  return (
    <View style={style}>
      <FeedAdView
        key={adId}  // 关键：强制重新创建组件实例
        codeid={codeid}
        adWidth={375}
        visible={true}
        onAdLayout={(e) => onAdLoaded?.(e.nativeEvent)}
        onAdError={(e) => onAdError?.(e.nativeEvent)}
        onAdClick={(e) => onAdClick?.(e.nativeEvent)}
        onAdClose={(e) => onAdClose?.(e.nativeEvent)}
      />
    </View>
  );
};

export default NativeAd;
```

**使用封装的组件**：

```tsx
import { NativeAd } from './NativeAd';

// 在列表中使用 - 只需传入 adId
<FlatList
  data={data}
  renderItem={({ item, index }) => (
    <View>
      <Text>{item.title}</Text>
      {/* 第5位和第10位插入不同广告 */}
      {index === 5 && <NativeAd adId="ad_5_1707123456789" />}
      {index === 10 && <NativeAd adId="ad_10_1707123456790" />}
    </View>
  )}
/>
```

**关键点说明**：

| 参数 | 说明 | 示例 |
|------|------|------|
| `adId` | 唯一广告标识，用于区分不同位置的广告 | `ad_5_1707123456789` |
| `key={adId}` | 强制 React 重新创建组件实例，确保每次展示不同广告 | - |
| `getSlotIdByAdId` | 根据 `adId` 哈希计算选择广告位，实现轮询 | - |
| `slotID` | 可选参数，直接指定广告位 ID | `your_codeid_1` |

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
