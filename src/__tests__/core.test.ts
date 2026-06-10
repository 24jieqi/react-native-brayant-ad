import {
  isEventForCurrentCandidate,
  resolveAdSlotIds,
  shouldTryNextCandidate,
} from '../core/candidates';
import { createAdRequest } from '../core/request';
import { AdLifecycle, FullscreenSettlement } from '../core/state-machine';
import type { AdEvent, AdPreloadToken, AdRequest } from '../core/types';

describe('广告请求', () => {
  it('清理重复和空广告位，并生成唯一请求 ID', () => {
    const first = createAdRequest({
      format: 'feed',
      slotIds: ['slot-a', '', 'slot-a', ' slot-b '],
      scene: 'home',
    });
    const second = createAdRequest({
      format: 'feed',
      slotIds: ['slot-a'],
      scene: 'home',
    });

    expect(first.slotIds).toEqual(['slot-a', 'slot-b']);
    expect(first.requestId).not.toBe(second.requestId);
  });

  it('拒绝空广告位请求', () => {
    expect(() =>
      createAdRequest({
        format: 'banner',
        slotIds: [''],
        scene: 'message',
      })
    ).toThrow('广告请求至少需要一个有效广告位');
  });
});

describe('广告生命周期', () => {
  it('只允许规定的状态迁移', () => {
    const lifecycle = new AdLifecycle();

    expect(lifecycle.transition('loading')).toBe(true);
    expect(lifecycle.transition('rendering')).toBe(false);
    expect(lifecycle.transition('loaded')).toBe(true);
    expect(lifecycle.transition('rendering')).toBe(true);
    expect(lifecycle.transition('presented')).toBe(true);
    expect(lifecycle.finish('closed')).toBe(true);
    expect(lifecycle.finish('failed')).toBe(false);
    expect(lifecycle.state).toBe('terminal');
  });

  it('全屏请求只接受第一个终态', async () => {
    const settlement = new FullscreenSettlement();
    const first = {
      requestId: 'splash-1',
      slotId: 'slot-a',
      status: 'closed' as const,
      elapsedMs: 120,
    };

    expect(settlement.settle(first)).toBe(true);
    expect(
      settlement.settle({
        ...first,
        status: 'failed',
      })
    ).toBe(false);
    await expect(settlement.result).resolves.toEqual(first);
  });
});

describe('候选广告位', () => {
  const request: AdRequest = {
    requestId: 'feed-1',
    format: 'feed',
    slotIds: ['primary', 'secondary'],
    scene: 'test',
    size: { width: 320, height: 100 },
  };
  const failedEvent: AdEvent = {
    requestId: request.requestId,
    format: 'feed',
    slotId: 'primary',
    state: 'terminal',
    source: 'realtime',
    elapsedMs: 20,
    error: {
      code: 'NO_FILL',
      message: '无填充',
    },
  };

  it('主广告位失败后按顺序尝试备用广告位', () => {
    expect(
      shouldTryNextCandidate({
        candidateIndex: 0,
        event: failedEvent,
        slotCount: request.slotIds.length,
      })
    ).toBe(true);
    expect(resolveAdSlotIds(request)).toEqual(['primary', 'secondary']);
  });

  it('成功、点击或最后一个广告位不触发回退', () => {
    expect(
      shouldTryNextCandidate({
        candidateIndex: 0,
        event: { ...failedEvent, state: 'presented', error: undefined },
        slotCount: 2,
      })
    ).toBe(false);
    expect(
      shouldTryNextCandidate({
        candidateIndex: 0,
        event: { ...failedEvent, action: 'click', error: undefined },
        slotCount: 2,
      })
    ).toBe(false);
    expect(
      shouldTryNextCandidate({
        candidateIndex: 1,
        event: failedEvent,
        slotCount: 2,
      })
    ).toBe(false);
  });

  it('预加载资源失败后继续尝试后续备用广告位', () => {
    expect(
      shouldTryNextCandidate({
        candidateIndex: 0,
        event: { ...failedEvent, source: 'preloaded' },
        slotCount: 2,
      })
    ).toBe(true);
  });

  it('预加载令牌先使用令牌广告位，失败后按请求顺序继续', () => {
    const token: AdPreloadToken = {
      token: 'token-1',
      requestId: 'preload-1',
      format: 'feed',
      slotId: 'primary',
      expiresAt: Date.now() + 60_000,
    };

    expect(resolveAdSlotIds(request, token)).toEqual(['primary', 'secondary']);
  });

  it('预加载命中备用广告位时，失败后仍会尝试主广告位', () => {
    const token: AdPreloadToken = {
      token: 'token-secondary',
      requestId: 'preload-secondary',
      format: 'feed',
      slotId: 'secondary',
      expiresAt: Date.now() + 60_000,
    };

    expect(resolveAdSlotIds(request, token)).toEqual(['secondary', 'primary']);
  });

  it('忽略其他请求、其他广告位和已切换广告位的迟到事件', () => {
    expect(
      isEventForCurrentCandidate({
        event: failedEvent,
        requestId: request.requestId,
        slotId: 'primary',
      })
    ).toBe(true);
    expect(
      isEventForCurrentCandidate({
        event: { ...failedEvent, requestId: 'other-request' },
        requestId: request.requestId,
        slotId: 'primary',
      })
    ).toBe(false);
    expect(
      isEventForCurrentCandidate({
        event: failedEvent,
        requestId: request.requestId,
        slotId: 'secondary',
      })
    ).toBe(false);
  });
});
