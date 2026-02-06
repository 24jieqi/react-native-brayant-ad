import React, { useState, useRef, useEffect } from 'react';
import {
  Platform,
  requireNativeComponent,
  UIManager,
  View,
  findNodeHandle,
  NativeModules,
  NativeEventEmitter,
} from 'react-native';
import type { EventSubscription, ViewStyle } from 'react-native';

// BannerAd currently only supports Android platform
const ComponentName = Platform.select({
  android: 'BannerAdViewManager',
  ios: undefined,
}) as string | undefined;
const { PangleAdModule } = NativeModules;

export interface BannerAdEvent {
  message?: string;
  width?: number;
  height?: number;
  reason?: string;
}

export interface BannerAdProps {
  codeid: string;
  style?: ViewStyle;
  adWidth?: number;
  adHeight?: number;
  visible?: boolean;
  onAdRenderSuccess?: (event: BannerAdEvent) => void;
  onAdError?: (event: BannerAdEvent) => void;
  onAdDismiss?: (event: BannerAdEvent) => void;
  onAdClick?: (event: BannerAdEvent) => void;
  onAdShow?: (event: BannerAdEvent) => void;
  onAdDislike?: (event: BannerAdEvent) => void;
}

const LINKING_ERROR =
  `The package 'react-native-brayant-ad' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// Lazy load native component to avoid duplicate registration on hot reload
type BannerAdComponentType = React.ComponentType<BannerAdProps> | null;
let BannerAdNativeComponent: BannerAdComponentType = null;

const getBannerAdComponent = (): BannerAdComponentType => {
  if (BannerAdNativeComponent === null) {
    if (
      ComponentName &&
      UIManager.getViewManagerConfig(ComponentName) != null
    ) {
      BannerAdNativeComponent =
        requireNativeComponent<BannerAdProps>(ComponentName);
    } else {
      BannerAdNativeComponent = null;
    }
  }
  return BannerAdNativeComponent;
};

const BannerAdView = (props: BannerAdProps) => {
  const {
    codeid,
    style,
    adWidth = 320,
    adHeight = 50,
    onAdRenderSuccess,
    onAdError,
    onAdDismiss,
    onAdClick,
    onAdShow,
    onAdDislike,
    visible = true,
  } = props;

  // All hooks must be called at the top level, unconditionally
  const [dismissed, setDismissed] = useState(false);
  const [height, setHeight] = useState(adHeight);
  const heightInitialized = useRef(false);
  const iosContainerRef = useRef<View | null>(null);

  // Reset state when visible changes from false to true to allow re-display
  useEffect(() => {
    if (visible) {
      setDismissed(false);
      heightInitialized.current = false;
      setHeight(adHeight);
    }
  }, [visible, adHeight]);

  useEffect(() => {
    if (Platform.OS !== 'ios' || !PangleAdModule || !visible || dismissed) {
      return;
    }

    const emitter = new NativeEventEmitter(PangleAdModule);
    const subscriptions: EventSubscription[] = [];
    const fixedSizeType = 3;

    const showBanner = () => {
      const tag = findNodeHandle(iosContainerRef.current);
      if (!tag) {
        return;
      }

      PangleAdModule.showBannerAd(tag).catch((error: unknown) => {
        onAdError?.({ message: String(error) });
      });
    };

    subscriptions.push(
      emitter.addListener('PangleBannerAdLoaded', () => {
        setTimeout(showBanner, 50);
      })
    );
    subscriptions.push(
      emitter.addListener('PangleBannerAdLoadFail', (event: BannerAdEvent) => {
        onAdError?.(event);
      })
    );
    subscriptions.push(
      emitter.addListener('PangleBannerAdRenderSuccess', () => {
        if (!heightInitialized.current) {
          heightInitialized.current = true;
          setHeight(adHeight);
        }
        onAdRenderSuccess?.({ width: adWidth, height: adHeight });
      })
    );
    subscriptions.push(
      emitter.addListener('PangleBannerAdShowed', (event: BannerAdEvent) => {
        onAdShow?.(event);
      })
    );
    subscriptions.push(
      emitter.addListener('PangleBannerAdClicked', (event: BannerAdEvent) => {
        onAdClick?.(event);
      })
    );
    subscriptions.push(
      emitter.addListener('PangleBannerAdClosed', (event: BannerAdEvent) => {
        setDismissed(true);
        onAdDismiss?.(event);
      })
    );

    PangleAdModule.loadBannerAdWithSize(
      codeid,
      fixedSizeType,
      adWidth,
      adHeight
    );

    return () => {
      subscriptions.forEach((subscription) => subscription.remove());
      PangleAdModule.hideBannerAd?.();
      PangleAdModule.removeBannerAd?.();
    };
  }, [
    adHeight,
    adWidth,
    codeid,
    dismissed,
    onAdClick,
    onAdDismiss,
    onAdError,
    onAdRenderSuccess,
    onAdShow,
    visible,
  ]);

  // Early returns after all hooks
  if (!visible || dismissed) {
    return null;
  }

  if (Platform.OS === 'ios') {
    if (!PangleAdModule) {
      throw new Error(LINKING_ERROR);
    }
    return (
      <View
        ref={iosContainerRef}
        style={{ width: adWidth, height, ...style }}
      />
    );
  }

  const NativeComponent = getBannerAdComponent();

  if (!NativeComponent) {
    throw new Error(LINKING_ERROR);
  }

  return (
    <NativeComponent
      codeid={codeid}
      adWidth={adWidth}
      adHeight={height}
      style={{ width: adWidth, height, ...style }}
      onAdError={(e: any) => onAdError?.(e.nativeEvent)}
      onAdClick={(e: any) => onAdClick?.(e.nativeEvent)}
      onAdDismiss={(e: any) => {
        setDismissed(true);
        onAdDismiss?.(e.nativeEvent);
      }}
      onAdShow={(e: any) => onAdShow?.(e.nativeEvent)}
      onAdRenderSuccess={(e: any) => {
        const newHeight = e.nativeEvent.height;
        if (newHeight && !heightInitialized.current) {
          setHeight(newHeight + 10);
          heightInitialized.current = true;
        }
        onAdRenderSuccess?.(e.nativeEvent);
      }}
      onAdDislike={(e: any) => {
        setDismissed(true);
        onAdDislike?.(e.nativeEvent);
      }}
    />
  );
};

export default React.memo(BannerAdView, (prevProps, nextProps) => {
  return (
    prevProps.codeid === nextProps.codeid &&
    prevProps.visible === nextProps.visible &&
    prevProps.adWidth === nextProps.adWidth &&
    prevProps.adHeight === nextProps.adHeight
  );
});
