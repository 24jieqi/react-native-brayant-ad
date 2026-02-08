import { NativeModules, Platform } from 'react-native';
import {
  init,
  loadFeedAd,
  preloadFeedAd,
  requestPermission,
} from './dy/api/AdManager';
import startRewardVideo from './dy/api/RewardVideo';
import {
  dyLoadSplashAd,
  preloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
} from './dy/api/SplashAd';
import { DrawFeedView, loadDrawFeedAd } from './dy/component/DrawFeedAd';
import FeedAdView from './dy/component/FeedAd';
import BannerAdView from './dy/component/BannerAd';

import startFullScreenVideo from './dy/api/FullScreenVideo';
import startInterstitialAd from './dy/api/InterstitialAd';
const LINKING_ERROR =
  `The package 'react-native-brayant-ad' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const BrayantAd = NativeModules.BrayantAd
  ? NativeModules.BrayantAd
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function multiply(a: number, b: number): Promise<number> {
  return BrayantAd.multiply(a, b);
}
export {
  init,
  loadFeedAd,
  preloadFeedAd,
  requestPermission,
  loadDrawFeedAd,
  startRewardVideo,
  startFullScreenVideo,
  startInterstitialAd,
  dyLoadSplashAd,
  preloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
  DrawFeedView,
  FeedAdView,
  BannerAdView,
};
