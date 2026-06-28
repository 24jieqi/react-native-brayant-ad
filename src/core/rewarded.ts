import { showFullscreenAd } from './fullscreen';
import type {
  FullscreenAdParams,
  RewardedAdRequest,
  RewardedAdResult,
} from './types';

export const showRewardedAd = async (
  params: Omit<FullscreenAdParams, 'request'> & {
    request: RewardedAdRequest;
  }
): Promise<RewardedAdResult> => {
  if (params.request.format !== 'rewarded') {
    throw new Error('showRewardedAd 仅接受 rewarded 请求');
  }
  return (await showFullscreenAd(params)) as RewardedAdResult;
};
