import { NativeModules, Platform } from 'react-native';
import type { NativeModule } from 'react-native';
import type {
  AdPreloadToken,
  AdRequest,
  AdSdkConfig,
  FullscreenAdResult,
} from './types';

export interface NativeAdV2Module extends NativeModule {
  initializeAdSdk: (config: AdSdkConfig) => Promise<boolean>;
  preloadAd: (request: AdRequest) => Promise<AdPreloadToken>;
  showSplashAdV2: (params: {
    request: AdRequest;
    preloadToken?: AdPreloadToken;
    timeoutMs: number;
  }) => Promise<FullscreenAdResult>;
}

const LINKING_ERROR =
  `包“@24jieqi/react-native-brayant-ad”未正确链接。\n` +
  Platform.select({ ios: '请先执行 pod install。\n', default: '' }) +
  '安装后需要重新构建原生应用。';

const nativeModule = (
  Platform.OS === 'ios' ? NativeModules.PangleAdModule : NativeModules.AdManager
) as NativeAdV2Module | undefined;

export const getNativeAdV2Module = (): NativeAdV2Module => {
  if (!nativeModule) {
    throw new Error(LINKING_ERROR);
  }
  return nativeModule;
};
