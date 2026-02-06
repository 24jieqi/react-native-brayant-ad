import { NativeModules, NativeEventEmitter, Platform } from 'react-native';
import type { EventSubscription } from 'react-native';
const { RewardVideoModule, PangleAdModule } = NativeModules;
export enum AD_EVENT_TYPE {
  onAdError = 'onAdError', // 广告加载失败监听
  onAdLoaded = 'onAdLoaded', // 广告加载成功监听
  onAdClick = 'onAdClick', // 广告被点击监听
  onAdClose = 'onAdClose', // 广告关闭监听
}

type ListenerCache = {
  [K in AD_EVENT_TYPE]: EventSubscription | undefined;
};

type rewardInfo = {
  codeid: string;
};

export default function (info: rewardInfo) {
  if (Platform.OS === 'ios') {
    if (!PangleAdModule) {
      const result = Promise.reject(new Error('PangleAdModule 未注册'));
      return {
        result,
        subscribe: () => ({ remove: () => {} }),
        cleanup: () => {},
      };
    }

    const eventEmitter = new NativeEventEmitter(PangleAdModule);
    const listenerCache: ListenerCache = {} as ListenerCache;
    const result = (async () => {
      PangleAdModule.loadInterstitialAd(info.codeid);

      const maxRetry = 40;
      for (let i = 0; i < maxRetry; i += 1) {
        const ready = await PangleAdModule.isInterstitialAdReady();
        if (ready) {
          return PangleAdModule.showInterstitialAd();
        }
        await new Promise<void>((resolve) => {
          setTimeout(resolve, 120);
        });
      }

      throw new Error('激励广告加载超时');
    })();

    return {
      result,
      subscribe: (type: AD_EVENT_TYPE, callback: (event: any) => void) => {
        if (listenerCache[type]) {
          listenerCache[type]?.remove();
        }

        const eventMap: Record<AD_EVENT_TYPE, string> = {
          [AD_EVENT_TYPE.onAdError]: 'PangleInterstitialAdLoadFail',
          [AD_EVENT_TYPE.onAdLoaded]: 'PangleInterstitialAdLoaded',
          [AD_EVENT_TYPE.onAdClick]: 'PangleInterstitialAdClicked',
          [AD_EVENT_TYPE.onAdClose]: 'PangleInterstitialAdClosed',
        };

        return (listenerCache[type] = eventEmitter.addListener(
          eventMap[type],
          (event: any) => {
            callback(event);
          }
        ));
      },
      cleanup: () => {
        Object.values(listenerCache).forEach((subscription) => {
          subscription?.remove();
        });
        Object.keys(listenerCache).forEach((key) => {
          delete listenerCache[key as AD_EVENT_TYPE];
        });
      },
    };
  }

  const eventEmitter = new NativeEventEmitter(RewardVideoModule);
  // Per-instance listener cache to avoid conflicts with multiple ads
  const listenerCache: ListenerCache = {} as ListenerCache;
  let result = RewardVideoModule.startAd(info);
  return {
    result,
    subscribe: (type: AD_EVENT_TYPE, callback: (event: any) => void) => {
      // Remove previous listener for this type in this instance only
      if (listenerCache[type]) {
        listenerCache[type]?.remove();
      }
      return (listenerCache[type] = eventEmitter.addListener(
        'RewardVideo-' + type,
        (event: any) => {
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
        delete listenerCache[key as AD_EVENT_TYPE];
      });
    },
  };
}
