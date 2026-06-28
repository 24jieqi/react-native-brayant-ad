import { showFullscreenAd } from './fullscreen';
import type {
  FullscreenAdParams,
  InterstitialAdRequest,
  InterstitialAdResult,
} from './types';

export const showInterstitialAd = async (
  params: Omit<FullscreenAdParams, 'request'> & {
    request: InterstitialAdRequest;
  }
): Promise<InterstitialAdResult> => {
  if (params.request.format !== 'interstitial') {
    throw new Error('showInterstitialAd 仅接受 interstitial 请求');
  }
  return (await showFullscreenAd(params)) as InterstitialAdResult;
};
