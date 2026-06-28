import { createLegacyFullscreenAd } from './fullscreenAdapter';

export enum AD_EVENT_TYPE {
  onAdError = 'onAdError',
  onAdLoaded = 'onAdLoaded',
  onAdClick = 'onAdClick',
  onAdClose = 'onAdClose',
}

export interface RewardVideoInfo {
  codeid: string;
  userId?: string;
  rewardName?: string;
  rewardAmount?: number;
  extra?: string;
  provider?: '头条';
}

export default function startRewardVideo(info: RewardVideoInfo) {
  return createLegacyFullscreenAd({
    format: 'rewarded',
    codeid: info.codeid,
    reward: {
      userId: info.userId,
      rewardName: info.rewardName,
      rewardAmount: info.rewardAmount,
      extra: info.extra,
    },
  });
}
