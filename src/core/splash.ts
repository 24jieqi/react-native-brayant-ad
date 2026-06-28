import { getNativeAdV2Module } from './native';
import { claimPreloadToken } from './preload';
import { NativeEventEmitter } from 'react-native';
import {
  claimFullscreenRequest,
  releaseFullscreenRequest,
} from './fullscreen-lock';
import type {
  AdEvent,
  AdPreloadToken,
  AdRequest,
  FullscreenAdResult,
} from './types';

export const showSplashAd = async (params: {
  request: AdRequest;
  preloadToken?: AdPreloadToken;
  timeoutMs?: number;
  onEvent?: (event: AdEvent) => void;
}): Promise<FullscreenAdResult> => {
  if (params.request.format !== 'splash') {
    throw new Error('showSplashAd 仅接受 splash 请求');
  }

  const activeRequestId = claimFullscreenRequest(params.request.requestId);
  if (activeRequestId) {
    return {
      requestId: params.request.requestId,
      slotId: params.request.slotIds[0] ?? '',
      status: 'cancelled',
      elapsedMs: 0,
      error: {
        code: 'FULLSCREEN_BUSY',
        message: `已有全屏广告请求正在执行：${activeRequestId}`,
      },
    };
  }

  try {
    const nativeModule = getNativeAdV2Module();
    const preloadToken =
      params.preloadToken ?? claimPreloadToken(params.request);
    const subscription = new NativeEventEmitter(nativeModule).addListener(
      'BrayantAd-onEvent',
      (event: AdEvent) => {
        if (event.requestId === params.request.requestId) {
          params.onEvent?.(event);
        }
      }
    );
    try {
      return await nativeModule.showSplashAdV2({
        request: params.request,
        preloadToken,
        timeoutMs: params.timeoutMs ?? 8000,
      });
    } finally {
      subscription.remove();
    }
  } finally {
    releaseFullscreenRequest(params.request.requestId);
  }
};
