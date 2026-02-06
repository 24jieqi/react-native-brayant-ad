import { NativeModules, Platform } from 'react-native';
const { AdManager } = NativeModules;

const init = (info: AppInfo): Promise<boolean | string> => {
  return AdManager.init(info);
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
  return AdManager.loadFeedAd(info);
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
  AdManager.requestPermission();
};
export { init, loadFeedAd, preloadFeedAd, loadDrawFeedAd, requestPermission };
