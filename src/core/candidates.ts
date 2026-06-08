import type { AdEvent, AdPreloadToken, AdRequest } from './types';

export const resolveAdSlotId = (
  request: AdRequest,
  candidateIndex: number,
  preloadToken?: AdPreloadToken
): string => {
  const preloadCandidateIndex = preloadToken
    ? request.slotIds.indexOf(preloadToken.slotId)
    : -1;
  if (
    preloadToken &&
    (preloadCandidateIndex < 0 || candidateIndex === preloadCandidateIndex)
  ) {
    return preloadToken.slotId;
  }
  return request.slotIds[candidateIndex] ?? '';
};

export const isEventForCurrentCandidate = ({
  event,
  requestId,
  slotId,
}: {
  event: AdEvent;
  requestId: string;
  slotId: string;
}): boolean => event.requestId === requestId && event.slotId === slotId;

export const shouldTryNextCandidate = ({
  candidateIndex,
  event,
  hasPreloadToken: _hasPreloadToken,
  slotCount,
}: {
  candidateIndex: number;
  event: AdEvent;
  hasPreloadToken: boolean;
  slotCount: number;
}): boolean =>
  event.state === 'terminal' &&
  Boolean(event.error) &&
  candidateIndex < slotCount - 1;
