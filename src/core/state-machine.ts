import type {
  AdLifecycleState,
  AdTerminalStatus,
  FullscreenAdResult,
} from './types';

const transitions: Record<AdLifecycleState, readonly AdLifecycleState[]> = {
  idle: ['loading', 'terminal'],
  loading: ['loaded', 'terminal'],
  loaded: ['rendering', 'rendered', 'presented', 'terminal'],
  rendering: ['rendered', 'presented', 'terminal'],
  rendered: ['presented', 'terminal'],
  presented: ['terminal'],
  terminal: [],
};

export class AdLifecycle {
  private currentState: AdLifecycleState = 'idle';

  get state(): AdLifecycleState {
    return this.currentState;
  }

  transition(nextState: AdLifecycleState): boolean {
    if (!transitions[this.currentState].includes(nextState)) {
      return false;
    }

    this.currentState = nextState;
    return true;
  }

  finish(status: AdTerminalStatus): boolean {
    if (this.currentState === 'terminal') {
      return false;
    }

    this.currentState = 'terminal';
    return Boolean(status);
  }
}

export class FullscreenSettlement {
  private settled = false;
  private resolveResult: ((result: FullscreenAdResult) => void) | undefined;
  readonly result = new Promise<FullscreenAdResult>((resolve) => {
    this.resolveResult = resolve;
  });

  settle(result: FullscreenAdResult): boolean {
    if (this.settled) {
      return false;
    }

    this.settled = true;
    this.resolveResult?.(result);
    return true;
  }
}
