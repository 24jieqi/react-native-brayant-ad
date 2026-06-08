import { getNativeAdV2Module } from './native';
import type { AdFormat, AdPreloadToken, AdRequest } from './types';

const preloadTasks = new Map<string, Promise<AdPreloadToken>>();
const preloadedTokens = new Map<string, AdPreloadToken[]>();

const getProfileKey = (request: AdRequest): string =>
  [
    request.format,
    request.slotIds.join('|'),
    Math.round(request.size?.width ?? 0),
    Math.round(request.size?.height ?? 0),
  ].join(':');

const preload = (
  expectedFormat: AdFormat,
  request: AdRequest
): Promise<AdPreloadToken> => {
  if (request.format !== expectedFormat) {
    return Promise.reject(
      new Error(
        `预加载类型不匹配：期望 ${expectedFormat}，实际 ${request.format}`
      )
    );
  }

  const currentTask = preloadTasks.get(request.requestId);
  if (currentTask) {
    return currentTask;
  }

  const task = getNativeAdV2Module()
    .preloadAd(request)
    .then((token) => {
      const profileKey = getProfileKey(request);
      const tokens = preloadedTokens.get(profileKey) ?? [];
      preloadedTokens.set(profileKey, [
        ...tokens.filter((item) => item.expiresAt > Date.now()),
        token,
      ]);
      return token;
    })
    .finally(() => preloadTasks.delete(request.requestId));
  preloadTasks.set(request.requestId, task);
  return task;
};

export const preloadFeedAd = (request: AdRequest): Promise<AdPreloadToken> =>
  preload('feed', request);

export const preloadBannerAd = (request: AdRequest): Promise<AdPreloadToken> =>
  preload('banner', request);

export const preloadSplashAdV2 = (
  request: AdRequest
): Promise<AdPreloadToken> => preload('splash', request);

export const claimPreloadToken = (
  request: AdRequest
): AdPreloadToken | undefined => {
  const profileKey = getProfileKey(request);
  const tokens = preloadedTokens.get(profileKey);
  if (!tokens) {
    return undefined;
  }
  const now = Date.now();
  const token = tokens.find((item) => item.expiresAt > now);
  const remainingTokens = tokens.filter(
    (item) => item !== token && item.expiresAt > now
  );
  if (remainingTokens.length > 0) {
    preloadedTokens.set(profileKey, remainingTokens);
  } else {
    preloadedTokens.delete(profileKey);
  }
  return token;
};

export const resetPreloadTokensForTests = (): void => {
  preloadTasks.clear();
  preloadedTokens.clear();
};
