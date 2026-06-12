import type { StyleProp, ViewStyle } from 'react-native';

export type AdFormat = 'feed' | 'banner' | 'splash';

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
}

export interface AdEvent {
  requestId: string;
  format: AdFormat;
  slotId: string;
  state: AdLifecycleState;
  action?: 'click';
  source: 'preloaded' | 'realtime';
  elapsedMs: number;
  width?: number;
  height?: number;
  error?: AdError;
}

export interface FullscreenAdResult {
  requestId: string;
  slotId: string;
  status: AdTerminalStatus;
  elapsedMs: number;
  error?: AdError;
}

export interface InlineAdProps {
  request: AdRequest;
  preloadToken?: AdPreloadToken;
  visible?: boolean;
  style?: StyleProp<ViewStyle>;
  candidateTimeoutMs?: number;
  onEvent?: (event: AdEvent) => void;
}
