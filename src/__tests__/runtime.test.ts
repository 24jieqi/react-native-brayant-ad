import type {
  AdPreloadToken,
  AdRequest,
  FullscreenAdResult,
} from '../core/types';

const mockInitializeAdSdk = jest.fn();
const mockPreloadAd = jest.fn();
const mockShowSplashAdV2 = jest.fn();
const mockRemoveListener = jest.fn();

jest.mock('../core/native', () => ({
  getNativeAdV2Module: () => ({
    initializeAdSdk: mockInitializeAdSdk,
    preloadAd: mockPreloadAd,
    showSplashAdV2: mockShowSplashAdV2,
  }),
}));

jest.mock('react-native', () => ({
  NativeEventEmitter: class {
    addListener() {
      return { remove: mockRemoveListener };
    }
  },
}));

import {
  preloadBannerAd,
  claimPreloadToken,
  preloadFeedAd,
  preloadSplashAdV2,
  resetPreloadTokensForTests,
} from '../core/preload';
import { resetAdSdkForTests, initializeAdSdk } from '../core/sdk';
import { showSplashAd } from '../core/splash';

const createRequest = (
  requestId: string,
  format: AdRequest['format'] = 'feed'
): AdRequest => ({
  requestId,
  format,
  slotIds: ['slot-a'],
  scene: 'test',
  size: format === 'splash' ? undefined : { width: 320, height: 50 },
});

const createToken = (
  request: AdRequest,
  token: string,
  expiresAt = Date.now() + 60_000
): AdPreloadToken => ({
  token,
  requestId: request.requestId,
  format: request.format,
  slotId: request.slotIds[0] ?? '',
  expiresAt,
});

describe('SDK 初始化', () => {
  beforeEach(() => {
    resetAdSdkForTests();
    mockInitializeAdSdk.mockReset();
  });

  it('并发初始化只调用一次原生模块，后续复用结果', async () => {
    let resolveInitialization: ((value: boolean) => void) | undefined;
    mockInitializeAdSdk.mockReturnValue(
      new Promise<boolean>((resolve) => {
        resolveInitialization = resolve;
      })
    );
    const config = {
      appId: 'app-id',
      allowInitialization: true,
    };

    const first = initializeAdSdk(config);
    const second = initializeAdSdk(config);
    expect(mockInitializeAdSdk).toHaveBeenCalledTimes(1);

    resolveInitialization?.(true);
    await expect(first).resolves.toEqual({ initialized: true, reused: false });
    await expect(second).resolves.toEqual({ initialized: true, reused: false });
    await expect(initializeAdSdk(config)).resolves.toEqual({
      initialized: true,
      reused: true,
    });
    expect(mockInitializeAdSdk).toHaveBeenCalledTimes(1);
  });

  it('初始化失败后允许重试', async () => {
    mockInitializeAdSdk
      .mockRejectedValueOnce(new Error('初始化失败'))
      .mockResolvedValueOnce(true);
    const config = {
      appId: 'app-id',
      allowInitialization: true,
    };

    await expect(initializeAdSdk(config)).rejects.toThrow('初始化失败');
    await expect(initializeAdSdk(config)).resolves.toEqual({
      initialized: true,
      reused: false,
    });
    expect(mockInitializeAdSdk).toHaveBeenCalledTimes(2);
  });

  it('隐私未授权时不调用原生初始化', async () => {
    await expect(
      initializeAdSdk({
        appId: 'app-id',
        allowInitialization: false,
      })
    ).resolves.toEqual({ initialized: false, reused: false });
    expect(mockInitializeAdSdk).not.toHaveBeenCalled();
  });
});

describe('预加载令牌', () => {
  beforeEach(() => {
    resetPreloadTokensForTests();
    mockPreloadAd.mockReset();
  });

  it('同规格已有未消费令牌时复用令牌且不重复请求原生模块', async () => {
    const firstRequest = createRequest('feed-1');
    const secondRequest = createRequest('feed-2');
    const firstToken = createToken(firstRequest, 'token-1');
    mockPreloadAd.mockResolvedValue(firstToken);

    await preloadFeedAd(firstRequest);
    await expect(preloadFeedAd(secondRequest)).resolves.toEqual(firstToken);

    expect(claimPreloadToken(firstRequest)).toEqual(firstToken);
    expect(claimPreloadToken(firstRequest)).toBeUndefined();
    expect(mockPreloadAd).toHaveBeenCalledTimes(1);
  });

  it('忽略过期令牌', async () => {
    const request = createRequest('feed-expired');
    mockPreloadAd.mockResolvedValue(
      createToken(request, 'expired', Date.now() - 1)
    );

    await preloadFeedAd(request);

    expect(claimPreloadToken(request)).toBeUndefined();
  });

  it('同规格不同请求并发预加载只调用一次原生模块', async () => {
    const request = createRequest('feed-deduplicated');
    const anotherRequest = createRequest('feed-deduplicated-2');
    let resolvePreload: ((value: AdPreloadToken) => void) | undefined;
    mockPreloadAd.mockReturnValue(
      new Promise<AdPreloadToken>((resolve) => {
        resolvePreload = resolve;
      })
    );

    const first = preloadFeedAd(request);
    const second = preloadFeedAd(anotherRequest);

    expect(mockPreloadAd).toHaveBeenCalledTimes(1);
    resolvePreload?.(createToken(request, 'deduplicated'));
    await expect(first).resolves.toMatchObject({ token: 'deduplicated' });
    await expect(second).resolves.toMatchObject({ token: 'deduplicated' });
  });

  it('预加载失败后允许同一请求重试', async () => {
    const request = createRequest('feed-retry');
    mockPreloadAd
      .mockRejectedValueOnce(new Error('预加载失败'))
      .mockResolvedValueOnce(createToken(request, 'retry-success'));

    await expect(preloadFeedAd(request)).rejects.toThrow('预加载失败');
    await expect(preloadFeedAd(request)).resolves.toMatchObject({
      token: 'retry-success',
    });
    expect(mockPreloadAd).toHaveBeenCalledTimes(2);
  });

  it('拒绝类型不匹配的预加载请求且不调用原生模块', async () => {
    const request = createRequest('feed-mismatch');

    await expect(preloadBannerAd(request)).rejects.toThrow('预加载类型不匹配');
    expect(mockPreloadAd).not.toHaveBeenCalled();
  });

  it('按广告类型、广告位和尺寸隔离令牌', async () => {
    const baseRequest = createRequest('feed-base');
    const differentSize = {
      ...createRequest('feed-size'),
      size: { width: 321, height: 50 },
    };
    const differentSlot = {
      ...createRequest('feed-slot'),
      slotIds: ['slot-b'],
    };
    mockPreloadAd.mockResolvedValue(createToken(baseRequest, 'isolated-token'));

    await preloadFeedAd(baseRequest);

    expect(claimPreloadToken(differentSize)).toBeUndefined();
    expect(claimPreloadToken(differentSlot)).toBeUndefined();
    expect(claimPreloadToken(baseRequest)).toMatchObject({
      token: 'isolated-token',
    });
    expect(claimPreloadToken(baseRequest)).toBeUndefined();
  });
});

describe('开屏广告', () => {
  beforeEach(() => {
    resetPreloadTokensForTests();
    mockPreloadAd.mockReset();
    mockShowSplashAdV2.mockReset();
    mockRemoveListener.mockReset();
  });

  it('自动消费同规格的预加载令牌', async () => {
    const preloadRequest = createRequest('splash-preload', 'splash');
    const showRequest = createRequest('splash-show', 'splash');
    const token = createToken(preloadRequest, 'splash-token');
    const result: FullscreenAdResult = {
      requestId: showRequest.requestId,
      slotId: 'slot-a',
      status: 'closed',
      elapsedMs: 100,
    };
    mockPreloadAd.mockResolvedValue(token);
    mockShowSplashAdV2.mockResolvedValue(result);

    await preloadSplashAdV2(preloadRequest);
    await expect(showSplashAd({ request: showRequest })).resolves.toEqual(
      result
    );
    expect(mockShowSplashAdV2).toHaveBeenCalledWith({
      request: showRequest,
      preloadToken: token,
      timeoutMs: 8000,
    });
    expect(mockRemoveListener).toHaveBeenCalledTimes(1);
  });

  it('已有开屏请求执行时取消后续请求', async () => {
    const firstRequest = createRequest('splash-1', 'splash');
    const secondRequest = createRequest('splash-2', 'splash');
    let resolveFirst: ((value: FullscreenAdResult) => void) | undefined;
    mockShowSplashAdV2.mockReturnValue(
      new Promise<FullscreenAdResult>((resolve) => {
        resolveFirst = resolve;
      })
    );

    const first = showSplashAd({ request: firstRequest });
    await expect(
      showSplashAd({ request: secondRequest })
    ).resolves.toMatchObject({
      requestId: secondRequest.requestId,
      status: 'cancelled',
      error: { code: 'SPLASH_BUSY' },
    });

    resolveFirst?.({
      requestId: firstRequest.requestId,
      slotId: 'slot-a',
      status: 'closed',
      elapsedMs: 100,
    });
    await first;
  });

  it('只转发当前 requestId 的事件并在完成后移除监听', async () => {
    const request = createRequest('splash-events', 'splash');
    const onEvent = jest.fn();
    let nativeListener: ((event: unknown) => void) | undefined;
    const addListener = jest
      .spyOn(
        (
          jest.requireMock('react-native') as {
            NativeEventEmitter: new () => {
              addListener: (
                name: string,
                listener: (event: unknown) => void
              ) => { remove: () => void };
            };
          }
        ).NativeEventEmitter.prototype,
        'addListener'
      )
      .mockImplementation((_name, listener) => {
        nativeListener = listener as (event: unknown) => void;
        return { remove: mockRemoveListener };
      });
    mockShowSplashAdV2.mockImplementation(async () => {
      nativeListener?.({
        requestId: 'other-request',
        state: 'presented',
      });
      nativeListener?.({
        requestId: request.requestId,
        state: 'presented',
      });
      return {
        requestId: request.requestId,
        slotId: 'slot-a',
        status: 'closed',
        elapsedMs: 80,
      };
    });

    await showSplashAd({ request, onEvent });

    expect(onEvent).toHaveBeenCalledTimes(1);
    expect(onEvent).toHaveBeenCalledWith(
      expect.objectContaining({ requestId: request.requestId })
    );
    expect(mockRemoveListener).toHaveBeenCalledTimes(1);
    addListener.mockRestore();
  });

  it('原生调用失败后释放串行锁并允许重试', async () => {
    const request = createRequest('splash-retry', 'splash');
    mockShowSplashAdV2
      .mockRejectedValueOnce(new Error('展示失败'))
      .mockResolvedValueOnce({
        requestId: request.requestId,
        slotId: 'slot-a',
        status: 'skipped',
        elapsedMs: 100,
      });

    await expect(showSplashAd({ request })).rejects.toThrow('展示失败');
    await expect(showSplashAd({ request })).resolves.toMatchObject({
      status: 'skipped',
    });
    expect(mockShowSplashAdV2).toHaveBeenCalledTimes(2);
    expect(mockRemoveListener).toHaveBeenCalledTimes(2);
  });
});
