import { NativeEventEmitter } from 'react-native';
import { resolveAdSlotIds } from './candidates';
import {
  claimFullscreenRequest,
  releaseFullscreenRequest,
} from './fullscreen-lock';
import { getNativeAdV2Module } from './native';
import { claimPreloadToken } from './preload';
import type {
  AdEvent,
  AdFormat,
  AdRequest,
  FullscreenAdParams,
  InterstitialAdResult,
  RewardedAdResult,
} from './types';

const DEFAULT_LOAD_TIMEOUT_MS = 10_000;

type CommandResult = RewardedAdResult | InterstitialAdResult;

const createBusyResult = (
  request: AdRequest,
  activeRequestId: string
): CommandResult => {
  const base = {
    requestId: request.requestId,
    slotId: request.slotIds[0] ?? '',
    status: 'cancelled' as const,
    elapsedMs: 0,
    presented: false,
    videoCompleted: false,
    error: {
      code: 'FULLSCREEN_BUSY',
      message: `已有全屏广告请求正在执行：${activeRequestId}`,
    },
  };
  return base;
};

export const showFullscreenAd = async ({
  request,
  preloadToken,
  loadTimeoutMs = DEFAULT_LOAD_TIMEOUT_MS,
  onEvent,
}: FullscreenAdParams): Promise<CommandResult> => {
  const supportedFormats: readonly AdFormat[] = ['rewarded', 'interstitial'];
  if (!supportedFormats.includes(request.format)) {
    throw new Error('全屏广告仅接受 rewarded 或 interstitial 请求');
  }
  if (!Number.isFinite(loadTimeoutMs) || loadTimeoutMs <= 0) {
    throw new Error('loadTimeoutMs 必须大于 0');
  }

  const activeRequestId = claimFullscreenRequest(request.requestId);
  if (activeRequestId) {
    return createBusyResult(request, activeRequestId);
  }

  try {
    const nativeModule = getNativeAdV2Module();
    const effectiveToken = preloadToken ?? claimPreloadToken(request);
    const candidateSlotIds = resolveAdSlotIds(request, effectiveToken);
    const subscription = new NativeEventEmitter(nativeModule).addListener(
      'BrayantAd-onEvent',
      (event: AdEvent) => {
        if (event.requestId === request.requestId) {
          onEvent?.(event);
        }
      }
    );
    try {
      let lastResult: CommandResult | undefined;
      for (const slotId of candidateSlotIds) {
        const candidateRequest = { ...request, slotIds: [slotId] };
        const candidateToken =
          effectiveToken?.slotId === slotId ? effectiveToken : undefined;
        const result = await nativeModule.showFullscreenAdV2({
          request: candidateRequest,
          preloadToken: candidateToken,
          loadTimeoutMs,
        });
        lastResult = result;
        if (result.status !== 'failed' || result.presented) {
          return result;
        }
      }

      return (
        lastResult ?? {
          requestId: request.requestId,
          slotId: request.slotIds[0] ?? '',
          status: 'failed',
          elapsedMs: 0,
          presented: false,
          videoCompleted: false,
          error: {
            code: 'NO_AD_CANDIDATE',
            message: '没有可用的广告位',
            stage: 'load',
          },
        }
      );
    } finally {
      subscription.remove();
    }
  } finally {
    releaseFullscreenRequest(request.requestId);
  }
};
