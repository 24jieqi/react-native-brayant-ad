/**
 * @Author: 马海
 * @createdTime: 2024-05-2024/5/15 22:51
 * @description: 开屏广告
 */
import { NativeModules, NativeEventEmitter } from 'react-native';
import type { EventSubscription } from 'react-native';
const { SplashAd, PangleAdModule } = NativeModules;

export interface AD_EVENT_TYPE {
  onAdError: string; // 广告加载失败监听
  onAdClick: string; // 广告被点击监听
  onAdClose: string; // 广告关闭
  onAdSkip: string; // 用户点击跳过广告监听
  onAdShow: string; // 开屏广告开始展示
  onPreloadSuccess: string; // 预加载成功
  onPreloadFail: string; // 预加载失败
}

export interface SPLASHAD_PROPS_TYPE {
  codeid: string;
  anim?: 'default' | 'none' | 'catalyst' | 'slide' | 'fade';
}

export interface PRELOAD_OPTIONS_TYPE {
  codeid: string;
}

export interface PRELOAD_RESULT_TYPE {
  success: boolean;
  message: string;
}

export interface HAS_PRELOADED_RESULT_TYPE {
  hasAd: boolean;
  status: number;
}

const dyLoadSplashAd = ({ codeid, anim = 'default' }: SPLASHAD_PROPS_TYPE) => {
  if (PangleAdModule && !SplashAd) {
    const eventEmitter = new NativeEventEmitter(PangleAdModule);
    const listenerCache: Record<string, EventSubscription | undefined> = {};

    const result = (async () => {
      PangleAdModule.loadSplashAd(codeid);

      const maxRetry = 30;
      for (let i = 0; i < maxRetry; i += 1) {
        const ready = await PangleAdModule.isSplashAdReady();
        if (ready) {
          return PangleAdModule.showSplashAd();
        }
        await new Promise<void>((resolve) => {
          setTimeout(resolve, 100);
        });
      }
      throw new Error('开屏广告加载超时');
    })();

    return {
      result,
      subscribe: (
        type: keyof AD_EVENT_TYPE,
        callback: (event: any) => void
      ) => {
        if (listenerCache[type]) {
          listenerCache[type]?.remove();
        }

        if (type === 'onAdClose') {
          return (listenerCache[type] = eventEmitter.addListener(
            'PangleSplashAdClosed',
            (event: any) => {
              callback(event);
            }
          ));
        }

        return {
          remove: () => {},
        };
      },
      cleanup: () => {
        Object.values(listenerCache).forEach((subscription) => {
          subscription?.remove();
        });
        Object.keys(listenerCache).forEach((key) => {
          delete listenerCache[key];
        });
      },
    };
  }

  const eventEmitter = new NativeEventEmitter(SplashAd);
  // Per-instance listener cache to avoid conflicts with multiple ads
  const listenerCache: Record<string, EventSubscription | undefined> = {};
  let result = SplashAd.loadSplashAd({ codeid, anim });
  return {
    result,
    subscribe: (type: keyof AD_EVENT_TYPE, callback: (event: any) => void) => {
      // Remove previous listener for this type in this instance only
      if (listenerCache[type]) {
        listenerCache[type]?.remove();
      }
      return (listenerCache[type] = eventEmitter.addListener(
        'SplashAd-' + type,
        (event: any) => {
          console.log('SplashAd event type ', type);
          console.log('SplashAd event ', event);
          callback(event);
        }
      ));
    },
    // Provide cleanup method
    cleanup: () => {
      Object.values(listenerCache).forEach((subscription) => {
        subscription?.remove();
      });
      Object.keys(listenerCache).forEach((key) => {
        delete listenerCache[key];
      });
    },
  };
};

/**
 * 预加载开屏广告
 * 在应用启动时调用，提前加载广告，避免展示时出现白屏
 * @param options 预加载选项
 * @returns Promise<预加载结果>
 */
const preloadSplashAd = async (
  options: PRELOAD_OPTIONS_TYPE
): Promise<PRELOAD_RESULT_TYPE> => {
  if (PangleAdModule && !SplashAd) {
    PangleAdModule.loadSplashAd(options.codeid);
    return {
      success: true,
      message: 'iOS 已触发开屏广告加载',
    };
  }
  return SplashAd.preloadSplashAd(options);
};

/**
 * 检查是否有预加载的广告可用
 * @returns Promise<检查结果>
 */
const hasPreloadedSplashAd = async (): Promise<HAS_PRELOADED_RESULT_TYPE> => {
  if (PangleAdModule && !SplashAd) {
    const hasAd = await PangleAdModule.isSplashAdReady();
    return {
      hasAd,
      status: hasAd ? 1 : 0,
    };
  }
  return SplashAd.hasPreloadedAd();
};

/**
 * 清除预加载的广告缓存
 */
const clearPreloadedSplashAd = (): void => {
  if (PangleAdModule && !SplashAd) {
    return;
  }
  SplashAd.clearPreloadedAd();
};

export {
  dyLoadSplashAd,
  preloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
};
