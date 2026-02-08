import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import type { EventSubscription } from 'react-native';

const { FullScreenVideoModule, PangleAdModule } = NativeModules;

export enum AD_EVENT_TYPE {
  onAdError = 'onAdError',
  onAdLoaded = 'onAdLoaded',
  onAdClick = 'onAdClick',
  onAdClose = 'onAdClose',
}

interface InterstitialProps {
  codeid: string;
  orientation?: 'HORIZONTAL' | 'VERTICAL';
  provider?: '头条' | '腾讯' | '快手';
}

type ListenerCache = {
  [K in AD_EVENT_TYPE]: EventSubscription | undefined;
};

export default function startInterstitialAd(props: InterstitialProps) {
  if (Platform.OS === 'ios') {
    const { codeid } = props;
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
      PangleAdModule.loadInterstitialAd(codeid);

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

      throw new Error('插屏广告加载超时');
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

  if (!FullScreenVideoModule) {
    const result = Promise.reject(new Error('FullScreenVideoModule 未注册'));
    return {
      result,
      subscribe: () => ({ remove: () => {} }),
      cleanup: () => {},
    };
  }

  const { provider, codeid, orientation = 'VERTICAL' } = props;
  const eventEmitter = new NativeEventEmitter(FullScreenVideoModule);
  const listenerCache: ListenerCache = {} as ListenerCache;
  const result = FullScreenVideoModule.startAd({
    codeid,
    orientation,
    provider,
  });

  return {
    result,
    subscribe: (type: AD_EVENT_TYPE, callback: (event: any) => void) => {
      if (listenerCache[type]) {
        listenerCache[type]?.remove();
      }

      const eventMap: Record<AD_EVENT_TYPE, string> = {
        [AD_EVENT_TYPE.onAdError]: 'FullScreenVideoModule-onAdError',
        [AD_EVENT_TYPE.onAdLoaded]: 'FullScreenVideoModule-onAdShow',
        [AD_EVENT_TYPE.onAdClick]: 'FullScreenVideoModule-onAdClick',
        [AD_EVENT_TYPE.onAdClose]: 'FullScreenVideoModule-onAdClose',
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
