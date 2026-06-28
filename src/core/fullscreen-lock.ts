let activeRequestId: string | null = null;

export const claimFullscreenRequest = (requestId: string): string | null => {
  if (activeRequestId) {
    return activeRequestId;
  }
  activeRequestId = requestId;
  return null;
};

export const releaseFullscreenRequest = (requestId: string): void => {
  if (activeRequestId === requestId) {
    activeRequestId = null;
  }
};

export const resetFullscreenRequestForTests = (): void => {
  activeRequestId = null;
};
