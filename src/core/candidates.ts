import type { AdEvent, AdPreloadToken, AdRequest } from './types';

export const resolveAdSlotId = (
  request: AdRequest,
  candidateIndex: number,
  preloadToken?: AdPreloadToken
): string => preloadToken?.slotId ?? request.slotIds[candidateIndex] ?? '';

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
  hasPreloadToken,
  slotCount,
}: {
  candidateIndex: number;
  event: AdEvent;
  hasPreloadToken: boolean;
  slotCount: number;
}): boolean =>
  !hasPreloadToken &&
  event.state === 'terminal' &&
  Boolean(event.error) &&
  candidateIndex < slotCount - 1;
