import { createLegacyFullscreenAd } from './fullscreenAdapter';

export enum AD_EVENT_TYPE {
  onAdError = 'onAdError',
  onAdLoaded = 'onAdLoaded',
  onAdClick = 'onAdClick',
  onAdClose = 'onAdClose',
}

export interface FullScreenProps {
  codeid: string;
  orientation?: 'HORIZONTAL' | 'VERTICAL';
  provider?: '头条' | '腾讯' | '快手';
}

export default function startFullScreenVideo(props: FullScreenProps) {
  return createLegacyFullscreenAd({
    format: 'interstitial',
    codeid: props.codeid,
  });
}
