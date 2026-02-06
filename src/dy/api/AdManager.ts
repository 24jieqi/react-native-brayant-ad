import { NativeModules, Platform } from 'react-native';
const { AdManager, PangleAdModule } = NativeModules;

const init = (info: AppInfo): Promise<boolean | string> => {
  if (Platform.OS === 'android') {
    return AdManager.init(info);
  }

  if (Platform.OS === 'ios') {
    if (!PangleAdModule) {
      return Promise.reject(new Error('PangleAdModule 未注册'));
    }
    return PangleAdModule.initialize(info.appid).then(() => true);
  }

  return Promise.resolve(false);
};

type AppInfo = {
  appid: string;
  app?: string | null; //app名称
  uid?: string | null; //有些uid和穿山甲商务有合作的需要
  amount?: number | null; //奖励数量
  reward?: string | null; //奖励是啥
  debug?: boolean;
};

type FeedInfo = {
  codeid: string;
  adWidth?: number | string;
};

const loadFeedAd = (info: FeedInfo) => {
  //提前加载信息流FeedAd, 结果返回promise
  if (Platform.OS === 'android') {
    return AdManager.loadFeedAd(info);
  }

  if (Platform.OS === 'ios') {
    if (!PangleAdModule) {
      return Promise.reject(new Error('PangleAdModule 未注册'));
    }
    const width = Number(info.adWidth || 0);
    PangleAdModule.loadExpressNativeAdWithAdSize(info.codeid, width, 0);
    return Promise.resolve(true);
  }

  return Promise.resolve(true);
};

/**
 * 预加载信息流广告（FeedAd）- Android 专用
 * 在组件渲染前调用，提前加载广告数据，减少白屏时间
 * @param info - 广告配置信息
 * @returns Promise<void>
 */
const preloadFeedAd = (info: FeedInfo): Promise<void> => {
  if (Platform.OS === 'android') {
    return AdManager.preloadFeedAd(info);
  }
  if (Platform.OS === 'ios') {
    if (!PangleAdModule) {
      return Promise.reject(new Error('PangleAdModule 未注册'));
    }
    const width = Number(info.adWidth || 0);
    PangleAdModule.loadExpressNativeAdWithAdSize(info.codeid, width, 0);
  }
  return Promise.resolve();
};

const loadDrawFeedAd = (info: FeedInfo) => {
  //提前加载视频刷信息流DrawFeedAd, 无返回，暂时只写完android
  if (Platform.OS === 'android') {
    return AdManager.loadDrawFeedAd(info);
  }
};

// 主动看激励视频时，才检查这个权限
const requestPermission = () => {
  if (Platform.OS === 'android') {
    AdManager.requestPermission();
    return;
  }

  if (Platform.OS === 'ios' && PangleAdModule) {
    PangleAdModule.requestATT();
  }
};
export { init, loadFeedAd, preloadFeedAd, loadDrawFeedAd, requestPermission };
