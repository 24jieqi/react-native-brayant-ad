import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  Platform,
  requireNativeComponent,
  StyleSheet,
  UIManager,
  View,
} from 'react-native';
import type { NativeSyntheticEvent, StyleProp, ViewStyle } from 'react-native';
import type { AdEvent, InlineAdProps } from '../core/types';
import { claimPreloadToken } from '../core/preload';
import {
  isEventForCurrentCandidate,
  resolveAdSlotIds,
  shouldTryNextCandidate,
} from '../core/candidates';

const DEFAULT_CANDIDATE_TIMEOUT_MS = 6000;

interface NativeFeedAdProps {
  style?: StyleProp<ViewStyle>;
  requestId: string;
  codeid: string;
  preloadToken?: string;
  adWidth: number;
  visible: boolean;
  onAdEvent: (event: NativeSyntheticEvent<AdEvent>) => void;
}

const componentName =
  Platform.OS === 'ios' ? 'FeedAdView' : 'FeedAdViewManager';
const NativeFeedAd =
  UIManager.getViewManagerConfig(componentName) != null
    ? requireNativeComponent<NativeFeedAdProps>(componentName)
    : null;

export const FeedAd = ({
  request,
  preloadToken,
  visible = true,
  style,
  candidateTimeoutMs = DEFAULT_CANDIDATE_TIMEOUT_MS,
  onEvent,
}: InlineAdProps) => {
  const width = request.size?.width ?? 375;
  const [renderedHeight, setRenderedHeight] = useState(
    request.size?.height ?? 1
  );
  const effectiveToken = useMemo(
    () => preloadToken ?? claimPreloadToken(request),
    [preloadToken, request]
  );
  const candidateSlotIds = useMemo(
    () => resolveAdSlotIds(request, effectiveToken),
    [effectiveToken, request]
  );
  const [candidateIndex, setCandidateIndex] = useState(0);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const onEventRef = useRef(onEvent);
  const forwardedEventKeysRef = useRef<Set<string>>(new Set());
  const slotId = candidateSlotIds[candidateIndex] ?? '';

  useEffect(() => {
    onEventRef.current = onEvent;
  }, [onEvent]);

  const clearCandidateTimeout = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }
  }, []);

  useEffect(() => {
    setCandidateIndex(0);
    setRenderedHeight(request.size?.height ?? 1);
    forwardedEventKeysRef.current.clear();
  }, [candidateSlotIds, request.requestId, request.size?.height]);

  useEffect(() => {
    clearCandidateTimeout();
    if (!visible || !slotId || candidateTimeoutMs <= 0) {
      return;
    }

    const startedAt = Date.now();
    timeoutRef.current = setTimeout(() => {
      timeoutRef.current = null;
      if (candidateIndex < candidateSlotIds.length - 1) {
        setCandidateIndex((index) =>
          index === candidateIndex ? index + 1 : index
        );
        return;
      }

      onEventRef.current?.({
        requestId: request.requestId,
        format: 'feed',
        slotId,
        state: 'terminal',
        source:
          candidateIndex === 0 && effectiveToken?.slotId === slotId
            ? 'preloaded'
            : 'realtime',
        elapsedMs: Date.now() - startedAt,
        error: {
          code: 'FEED_TIMEOUT',
          message: `信息流广告位 ${slotId} 加载或渲染超时`,
        },
      });
    }, candidateTimeoutMs);

    return clearCandidateTimeout;
  }, [
    candidateIndex,
    candidateSlotIds.length,
    candidateTimeoutMs,
    clearCandidateTimeout,
    effectiveToken?.slotId,
    request.requestId,
    slotId,
    visible,
  ]);

  const handleEvent = useCallback(
    (event: AdEvent) => {
      if (
        !isEventForCurrentCandidate({
          event,
          requestId: request.requestId,
          slotId,
        })
      ) {
        return;
      }
      if (event.state === 'rendered' || event.state === 'presented') {
        clearCandidateTimeout();
        if (event.height && event.height > 0) {
          setRenderedHeight(Math.ceil(event.height));
        }
      }
      if (event.state === 'terminal') {
        clearCandidateTimeout();
      }
      const shouldTryNext = shouldTryNextCandidate({
        candidateIndex,
        event,
        slotCount: candidateSlotIds.length,
      });
      if (shouldTryNext) {
        setCandidateIndex((index) =>
          index === candidateIndex ? index + 1 : index
        );
        return;
      }
      const eventKey = `${event.slotId}:${event.state}:${event.action ?? ''}`;
      if (forwardedEventKeysRef.current.has(eventKey)) {
        return;
      }
      forwardedEventKeysRef.current.add(eventKey);
      onEventRef.current?.(event);
    },
    [
      candidateIndex,
      candidateSlotIds.length,
      clearCandidateTimeout,
      request.requestId,
      slotId,
    ]
  );

  if (request.format !== 'feed') {
    throw new Error('FeedAd 仅接受 feed 请求');
  }

  if (!visible) {
    return null;
  }

  if (!NativeFeedAd) {
    throw new Error('FeedAd 原生组件未正确链接');
  }

  return (
    <View style={[{ width, height: renderedHeight }, style]}>
      <NativeFeedAd
        key={`${request.requestId}:${slotId}`}
        style={StyleSheet.absoluteFillObject}
        requestId={request.requestId}
        codeid={slotId}
        preloadToken={
          candidateIndex === 0 && effectiveToken?.slotId === slotId
            ? effectiveToken.token
            : undefined
        }
        adWidth={width}
        visible={visible}
        onAdEvent={(event) => handleEvent(event.nativeEvent)}
      />
    </View>
  );
};
