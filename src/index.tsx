import { NativeModules, Platform } from 'react-native';
import {
  init,
  loadFeedAd,
  preloadFeedAd as legacyPreloadFeedAd,
  requestPermission,
} from './dy/api/AdManager';
import startRewardVideo from './dy/api/RewardVideo';
import {
  dyLoadSplashAd,
  preloadSplashAd as legacyPreloadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
} from './dy/api/SplashAd';
import { DrawFeedView, loadDrawFeedAd } from './dy/component/DrawFeedAd';
import FeedAdView from './dy/component/FeedAd';
import BannerAdView from './dy/component/BannerAd';

import startFullScreenVideo from './dy/api/FullScreenVideo';
import startInterstitialAd from './dy/api/InterstitialAd';
import { BannerAd } from './component/BannerAd';
import { FeedAd } from './component/FeedAd';
import { createAdRequest } from './core/request';
import {
  preloadBannerAd,
  preloadFeedAd,
  preloadSplashAdV2 as preloadSplashAd,
} from './core/preload';
import { initializeAdSdk } from './core/sdk';
import { showSplashAd } from './core/splash';
import type {
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
} from './core/types';
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
  requestPermission,
  loadDrawFeedAd,
  startRewardVideo,
  startFullScreenVideo,
  startInterstitialAd,
  dyLoadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
  DrawFeedView,
  FeedAdView,
  BannerAdView,
  initializeAdSdk,
  createAdRequest,
  preloadFeedAd,
  preloadBannerAd,
  preloadSplashAd,
  showSplashAd,
  FeedAd,
  BannerAd,
};

export const legacy = {
  init,
  loadFeedAd,
  preloadFeedAd: legacyPreloadFeedAd,
  preloadSplashAd: legacyPreloadSplashAd,
  dyLoadSplashAd,
  hasPreloadedSplashAd,
  clearPreloadedSplashAd,
  FeedAdView,
  BannerAdView,
};

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
