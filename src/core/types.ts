import type { StyleProp, ViewStyle } from 'react-native';

export type AdFormat =
  | 'feed'
  | 'banner'
  | 'splash'
  | 'rewarded'
  | 'interstitial';

export type AdEventAction = 'click' | 'skip' | 'video-complete' | 'reward';

export type AdLifecycleState =
  | 'idle'
  | 'loading'
  | 'loaded'
  | 'rendering'
  | 'rendered'
  | 'presented'
  | 'terminal';

export type AdTerminalStatus = 'closed' | 'skipped' | 'failed' | 'cancelled';

export interface AdSize {
  width: number;
  height?: number;
}

export interface AdRequest {
  requestId: string;
  format: AdFormat;
  slotIds: string[];
  scene: string;
  size?: AdSize;
  reward?: RewardedAdOptions;
}

export interface RewardedAdRequest extends AdRequest {
  format: 'rewarded';
  reward?: RewardedAdOptions;
}

export interface InterstitialAdRequest extends AdRequest {
  format: 'interstitial';
}

export interface RewardedAdOptions {
  userId?: string;
  rewardName?: string;
  rewardAmount?: number;
  extra?: string;
}

export interface AdSdkConfig {
  appId: string;
  appName?: string;
  debug?: boolean;
  allowInitialization: boolean;
}

export interface AdSdkInitResult {
  initialized: boolean;
  reused: boolean;
}

export interface AdPreloadToken {
  token: string;
  requestId: string;
  format: AdFormat;
  slotId: string;
  expiresAt: number;
}

export interface AdError {
  code: string;
  message: string;
  nativeCode?: number;
  stage?: 'load' | 'show' | 'playback';
}

export interface RewardVerification {
  valid: boolean;
  type?: number;
  name?: string;
  amount?: number;
  proposedAmount?: number;
  error?: AdError;
}

export interface AdEvent {
  requestId: string;
  format: AdFormat;
  slotId: string;
  state: AdLifecycleState;
  action?: AdEventAction;
  source: 'preloaded' | 'realtime';
  elapsedMs: number;
  width?: number;
  height?: number;
  error?: AdError;
  reward?: RewardVerification;
}

export interface FullscreenAdResult {
  requestId: string;
  slotId: string;
  status: AdTerminalStatus;
  elapsedMs: number;
  error?: AdError;
  presented?: boolean;
}

export interface RewardedAdResult extends FullscreenAdResult {
  presented: boolean;
  videoCompleted: boolean;
  reward?: RewardVerification;
}

export interface InterstitialAdResult extends FullscreenAdResult {
  presented: boolean;
  videoCompleted: boolean;
}

export interface FullscreenAdParams {
  request: AdRequest;
  preloadToken?: AdPreloadToken;
  loadTimeoutMs?: number;
  onEvent?: (event: AdEvent) => void;
}

export interface InlineAdProps {
  request: AdRequest;
  preloadToken?: AdPreloadToken;
  visible?: boolean;
  style?: StyleProp<ViewStyle>;
  candidateTimeoutMs?: number;
  onEvent?: (event: AdEvent) => void;
}
