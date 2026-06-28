import { Platform } from 'react-native';
import { createAdRequest } from '../../core/request';
import { showInterstitialAd } from '../../core/interstitial';
import { showRewardedAd } from '../../core/rewarded';
import type {
  AdEvent,
  InterstitialAdResult,
  RewardedAdOptions,
  RewardedAdResult,
} from '../../core/types';

export type LegacyFullscreenEvent =
  | 'onAdError'
  | 'onAdLoaded'
  | 'onAdClick'
  | 'onAdClose';

type LegacyCallback = (event: unknown) => void;

const toLegacyResult = (
  result: RewardedAdResult | InterstitialAdResult,
  clicked: boolean
): unknown => {
  if (Platform.OS === 'ios') {
    return {
      completed: result.status === 'closed' || result.status === 'skipped',
    };
  }
  return JSON.stringify({
    video_play: result.presented,
    ad_click: clicked,
    apk_install: false,
    verify_status: 'reward' in result ? Boolean(result.reward?.valid) : false,
  });
};

export const createLegacyFullscreenAd = ({
  format,
  codeid,
  reward,
}: {
  format: 'rewarded' | 'interstitial';
  codeid: string;
  reward?: RewardedAdOptions;
}) => {
  const listeners = new Map<LegacyFullscreenEvent, LegacyCallback>();
  const pendingEvents = new Map<LegacyFullscreenEvent, unknown>();
  let clicked = false;
  let disposed = false;

  const dispatch = (type: LegacyFullscreenEvent, event: unknown): void => {
    if (disposed) return;
    const listener = listeners.get(type);
    if (listener) {
      listener(event);
    } else {
      pendingEvents.set(type, event);
    }
  };

  const onEvent = (event: AdEvent): void => {
    if (event.state === 'loaded') {
      dispatch('onAdLoaded', event);
    }
    if (event.action === 'click') {
      clicked = true;
      dispatch('onAdClick', event);
    }
    if (event.state === 'terminal' && event.error) {
      dispatch('onAdError', event);
    }
    if (event.state === 'terminal' && !event.error) {
      dispatch('onAdClose', event);
    }
  };

  const result = (
    format === 'rewarded'
      ? showRewardedAd({
          request: createAdRequest({
            format: 'rewarded',
            slotIds: [codeid],
            scene: 'legacy-rewarded',
            reward,
          }),
          onEvent,
        })
      : showInterstitialAd({
          request: createAdRequest({
            format: 'interstitial',
            slotIds: [codeid],
            scene: 'legacy-interstitial',
          }),
          onEvent,
        })
  ).then((value) => toLegacyResult(value, clicked));

  return {
    result,
    subscribe: (type: LegacyFullscreenEvent, callback: LegacyCallback) => {
      listeners.set(type, callback);
      if (pendingEvents.has(type)) {
        callback(pendingEvents.get(type));
        pendingEvents.delete(type);
      }
      return {
        remove: () => {
          if (listeners.get(type) === callback) listeners.delete(type);
        },
      };
    },
    cleanup: () => {
      disposed = true;
      listeners.clear();
      pendingEvents.clear();
    },
  };
};
