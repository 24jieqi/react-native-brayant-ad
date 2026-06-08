import type { AdFormat, AdRequest, AdSize } from './types';

let requestSeed = 0;

const normalizeSlotIds = (slotIds: string[]): string[] => [
  ...new Set(slotIds.map((slotId) => slotId.trim()).filter(Boolean)),
];

export const createAdRequest = (input: {
  format: AdFormat;
  slotIds: string[];
  scene: string;
  size?: AdSize;
  requestId?: string;
}): AdRequest => {
  const slotIds = normalizeSlotIds(input.slotIds);
  if (slotIds.length === 0) {
    throw new Error('广告请求至少需要一个有效广告位');
  }

  requestSeed += 1;

  return {
    requestId:
      input.requestId ??
      `${input.format}:${Date.now().toString(36)}:${requestSeed.toString(36)}`,
    format: input.format,
    slotIds,
    scene: input.scene,
    size: input.size,
  };
};
