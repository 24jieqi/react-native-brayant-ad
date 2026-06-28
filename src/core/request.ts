import type { AdFormat, AdRequest, AdSize, RewardedAdOptions } from './types';

let requestSeed = 0;

const normalizeSlotIds = (slotIds: string[]): string[] => [
  ...new Set(slotIds.map((slotId) => slotId.trim()).filter(Boolean)),
];

const normalizeOptionalString = (value?: string): string | undefined => {
  const normalized = value?.trim();
  return normalized ? normalized : undefined;
};

const normalizeReward = (
  reward?: RewardedAdOptions
): RewardedAdOptions | undefined => {
  if (!reward) {
    return undefined;
  }

  if (
    reward.rewardAmount !== undefined &&
    (!Number.isInteger(reward.rewardAmount) || reward.rewardAmount <= 0)
  ) {
    throw new Error('rewardAmount 必须是正整数');
  }

  const extra = normalizeOptionalString(reward.extra);
  if (extra) {
    let parsed: unknown;
    try {
      parsed = JSON.parse(extra);
    } catch {
      throw new Error('extra 必须是合法的 JSON 对象字符串');
    }
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      throw new Error('extra 必须是合法的 JSON 对象字符串');
    }
  }

  const normalized: RewardedAdOptions = {
    userId: normalizeOptionalString(reward.userId),
    rewardName: normalizeOptionalString(reward.rewardName),
    rewardAmount: reward.rewardAmount,
    extra,
  };

  return Object.values(normalized).some((value) => value !== undefined)
    ? normalized
    : undefined;
};

export const createAdRequest = <TFormat extends AdFormat>(input: {
  format: TFormat;
  slotIds: string[];
  scene: string;
  size?: AdSize;
  reward?: RewardedAdOptions;
  requestId?: string;
}): AdRequest & { format: TFormat } => {
  const slotIds = normalizeSlotIds(input.slotIds);
  if (slotIds.length === 0) {
    throw new Error('广告请求至少需要一个有效广告位');
  }
  if (input.reward && input.format !== 'rewarded') {
    throw new Error('reward 参数仅适用于 rewarded 请求');
  }

  const scene = input.scene.trim();
  if (!scene) {
    throw new Error('广告请求必须提供有效场景');
  }

  const reward = normalizeReward(input.reward);

  requestSeed += 1;

  return {
    requestId:
      input.requestId ??
      `${input.format}:${Date.now().toString(36)}:${requestSeed.toString(36)}`,
    format: input.format,
    slotIds,
    scene,
    size: input.size,
    reward,
  };
};
