import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Platform,
  requireNativeComponent,
  UIManager,
  View,
} from 'react-native';
import type { NativeSyntheticEvent } from 'react-native';
import type { AdEvent, InlineAdProps } from '../core/types';
import { claimPreloadToken } from '../core/preload';
import {
  isEventForCurrentCandidate,
  resolveAdSlotId,
  shouldTryNextCandidate,
} from '../core/candidates';

interface NativeFeedAdProps {
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
  onEvent,
}: InlineAdProps) => {
  const [candidateIndex, setCandidateIndex] = useState(0);
  const width = request.size?.width ?? 375;
  const effectiveToken = useMemo(
    () => preloadToken ?? claimPreloadToken(request),
    [preloadToken, request]
  );
  const slotId = useMemo(
    () => resolveAdSlotId(request, candidateIndex, effectiveToken),
    [candidateIndex, effectiveToken, request]
  );

  useEffect(() => {
    setCandidateIndex(0);
  }, [request.requestId]);

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
      const shouldTryNext = shouldTryNextCandidate({
        candidateIndex,
        event,
        hasPreloadToken: Boolean(effectiveToken),
        slotCount: request.slotIds.length,
      });
      if (shouldTryNext) {
        setCandidateIndex((index) =>
          index === candidateIndex ? index + 1 : index
        );
        return;
      }
      onEvent?.(event);
    },
    [
      candidateIndex,
      effectiveToken,
      onEvent,
      request.requestId,
      request.slotIds.length,
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
    <View style={style}>
      <NativeFeedAd
        key={`${request.requestId}:${slotId}`}
        requestId={request.requestId}
        codeid={slotId}
        preloadToken={effectiveToken?.token}
        adWidth={width}
        visible={visible}
        onAdEvent={(event) => handleEvent(event.nativeEvent)}
      />
    </View>
  );
};
