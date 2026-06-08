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

interface NativeBannerAdProps {
  requestId: string;
  codeid: string;
  preloadToken?: string;
  adWidth: number;
  adHeight: number;
  visible: boolean;
  onAdEvent: (event: NativeSyntheticEvent<AdEvent>) => void;
}

const componentName =
  Platform.OS === 'ios' ? 'BrayantBannerAdView' : 'BannerAdViewManager';
const NativeBannerAd =
  UIManager.getViewManagerConfig(componentName) != null
    ? requireNativeComponent<NativeBannerAdProps>(componentName)
    : null;

export const BannerAd = ({
  request,
  preloadToken,
  visible = true,
  style,
  onEvent,
}: InlineAdProps) => {
  const width = request.size?.width ?? 320;
  const height = request.size?.height ?? 50;
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
  }, [initialCandidateIndex, request.requestId]);

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

  if (request.format !== 'banner') {
    throw new Error('BannerAd 仅接受 banner 请求');
  }

  if (!visible) {
    return null;
  }

  if (!NativeBannerAd) {
    throw new Error('BannerAd 原生组件未正确链接');
  }

  return (
    <View style={style}>
      <NativeBannerAd
        key={`${request.requestId}:${slotId}`}
        requestId={request.requestId}
        codeid={slotId}
        preloadToken={effectiveToken?.token}
        adWidth={width}
        adHeight={height}
        visible={visible}
        onAdEvent={(event) => handleEvent(event.nativeEvent)}
      />
    </View>
  );
};
