import React from 'react';
import { act, create } from 'react-test-renderer';
import type { ReactTestRenderer } from 'react-test-renderer';
import { StyleSheet, View } from 'react-native';
import type { AdEvent, AdRequest } from '../core/types';
import { FeedAd } from '../component/FeedAd';

jest.mock('react-native', () => ({
  Platform: { OS: 'ios' },
  UIManager: { getViewManagerConfig: () => ({}) },
  requireNativeComponent: () => 'NativeFeedAd',
  View: 'View',
  StyleSheet: {
    absoluteFillObject: {},
    flatten: (styles: object[]) => Object.assign({}, ...styles),
  },
}));
jest.mock('../core/preload', () => ({ claimPreloadToken: () => undefined }));

const request: AdRequest = {
  requestId: 'feed-size',
  format: 'feed',
  slotIds: ['feed-slot'],
  scene: 'test',
  size: { width: 279 },
};
const event = (state: AdEvent['state'], height: number): AdEvent => ({
  requestId: request.requestId,
  format: 'feed',
  slotId: 'feed-slot',
  source: 'realtime',
  elapsedMs: 1,
  state,
  width: 279,
  height,
});

describe('FeedAd 异步高度', () => {
  it('同状态尺寸变化继续传给外层，真实高度优先于旧的占位高度', () => {
    const onEvent = jest.fn();
    let tree!: ReactTestRenderer;
    act(() => {
      tree = create(
        <FeedAd
          request={request}
          onEvent={onEvent}
          candidateTimeoutMs={0}
          style={{ height: 120 }}
        />
      );
    });
    const send = (value: AdEvent) => {
      act(() => {
        tree.root
          .findByProps({ codeid: 'feed-slot' })
          .props.onAdEvent({ nativeEvent: value });
      });
    };
    send(event('rendered', 120));
    send(event('rendered', 380.2));
    expect(onEvent).toHaveBeenCalledTimes(2);
    expect(onEvent).toHaveBeenLastCalledWith(
      expect.objectContaining({ height: 380.2 })
    );
    expect(
      StyleSheet.flatten(tree.root.findByType(View).props.style).height
    ).toBe(381);
    send(event('rendered', 380.2));
    expect(onEvent).toHaveBeenCalledTimes(2);
    send(event('rendered', 120));
    expect(onEvent).toHaveBeenCalledTimes(3);
    expect(
      StyleSheet.flatten(tree.root.findByType(View).props.style).height
    ).toBe(120);
    send(event('presented', 420));
    expect(
      StyleSheet.flatten(tree.root.findByType(View).props.style).height
    ).toBe(420);
    send(event('rendered', Infinity));
    expect(
      StyleSheet.flatten(tree.root.findByType(View).props.style).height
    ).toBe(420);
    act(() => tree.unmount());
  });

  it('新请求重新使用占位尺寸，旧请求的事件不影响新广告', () => {
    let tree!: ReactTestRenderer;
    act(() => {
      tree = create(<FeedAd request={request} candidateTimeoutMs={0} />);
    });
    act(() => {
      tree.root
        .findByProps({ codeid: 'feed-slot' })
        .props.onAdEvent({ nativeEvent: event('rendered', 450) });
    });
    act(() => {
      tree.update(
        <FeedAd
          request={{ ...request, requestId: 'next-feed' }}
          candidateTimeoutMs={0}
        />
      );
    });
    act(() => {
      tree.root
        .findByProps({ codeid: 'feed-slot' })
        .props.onAdEvent({ nativeEvent: event('rendered', 600) });
    });
    expect(
      StyleSheet.flatten(tree.root.findByType(View).props.style).height
    ).toBe(1);
    act(() => tree.unmount());
  });
});
