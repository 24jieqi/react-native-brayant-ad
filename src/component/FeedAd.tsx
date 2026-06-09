import React, { useCallback, useEffect, useMemo, useState } from 'react';
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
  resolveAdSlotId,
  shouldTryNextCandidate,
} from '../core/candidates';

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
  const initialCandidateIndex = useMemo(() => {
    if (!effectiveToken) {
      return 0;
    }
    const tokenIndex = request.slotIds.indexOf(effectiveToken.slotId);
    return tokenIndex >= 0 ? tokenIndex : 0;
  }, [effectiveToken, request.slotIds]);
  const [candidateIndex, setCandidateIndex] = useState(initialCandidateIndex);
  const slotId = useMemo(
    () => resolveAdSlotId(request, candidateIndex, effectiveToken),
    [candidateIndex, effectiveToken, request]
  );

  useEffect(() => {
    setCandidateIndex(initialCandidateIndex);
    setRenderedHeight(request.size?.height ?? 1);
  }, [initialCandidateIndex, request.requestId, request.size?.height]);

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
      if (event.state === 'presented' && event.height && event.height > 0) {
        setRenderedHeight(Math.ceil(event.height));
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
    <View style={[{ width, height: renderedHeight }, style]}>
      <NativeFeedAd
        key={`${request.requestId}:${slotId}`}
        style={StyleSheet.absoluteFillObject}
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
