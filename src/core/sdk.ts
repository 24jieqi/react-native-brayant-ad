import { getNativeAdV2Module } from './native';
import type { AdSdkConfig, AdSdkInitResult } from './types';

let initializedAppId: string | null = null;
let initializationTask: Promise<AdSdkInitResult> | null = null;

export const initializeAdSdk = async (
  config: AdSdkConfig
): Promise<AdSdkInitResult> => {
  if (!config.allowInitialization) {
    return { initialized: false, reused: false };
  }

  if (initializedAppId === config.appId) {
    return { initialized: true, reused: true };
  }

  if (initializationTask) {
    return initializationTask;
  }

  initializationTask = (async () => {
    const initialized = await getNativeAdV2Module().initializeAdSdk(config);
    if (initialized) {
      initializedAppId = config.appId;
    }
    return { initialized, reused: false };
  })();

  try {
    return await initializationTask;
  } finally {
    initializationTask = null;
  }
};

export const resetAdSdkForTests = (): void => {
  initializedAppId = null;
  initializationTask = null;
};
