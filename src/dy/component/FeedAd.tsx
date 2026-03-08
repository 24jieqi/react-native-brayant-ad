/**
 * @Author: 马海
 * @createdTime: 2024-05-2024/5/20 22:00
 * @description: description
 */
import React, {
  useState,
  useCallback,
  useRef,
  useEffect,
  useMemo,
} from 'react';
import { Platform, requireNativeComponent, UIManager } from 'react-native';
import type { ViewStyle } from 'react-native';

const ComponentName = Platform.select({
  android: 'FeedAdViewManager',
  ios: 'FeedAdView',
  default: 'FeedAdViewManager',
}) as string;

export interface FeedAdProps {
  codeid: string;
  style?: ViewStyle;
  adWidth?: number;
  visible?: boolean;
  onAdLayout?: (event: FeedAdEvent) => void;
  onAdError?: (event: FeedAdEvent) => void;
  onAdClose?: (event: FeedAdEvent) => void;
  onAdClick?: (event: FeedAdEvent) => void;
}

export interface FeedAdEvent {
  message?: string;
  width?: number;
  height?: number;
  reason?: string;
}

const LINKING_ERROR =
  `The package 'react-native-brayant-ad' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// Lazy load native component to avoid duplicate registration on hot reload
type FeedAdComponentType = React.ComponentType<FeedAdProps> | null;
let FeedAdNativeComponent: FeedAdComponentType = null;

const getFeedAdComponent = (): FeedAdComponentType => {
  if (FeedAdNativeComponent === null) {
    if (UIManager.getViewManagerConfig(ComponentName) != null) {
      FeedAdNativeComponent =
        requireNativeComponent<FeedAdProps>(ComponentName);
    } else {
      FeedAdNativeComponent = null;
    }
  }
  return FeedAdNativeComponent;
};

const FeedAdView = (props: FeedAdProps) => {
  const {
    codeid,
    style,
    adWidth = 375,
    onAdLayout,
    onAdError,
    onAdClose,
    onAdClick,
    visible = true,
  } = props;

  // All hooks must be called at the top level, unconditionally
  const [closed, setClosed] = useState(false);
  const [height, setHeight] = useState(0);
  const heightInitialized = useRef(false);

  // Reset state when visible changes from false to true to allow re-display
  useEffect(() => {
    if (visible) {
      setClosed(false);
      heightInitialized.current = false;
      setHeight(0);
    }
  }, [visible]);

  // Use useMemo to cache style object and prevent unnecessary re-renders
  const containerStyle = useMemo(
    () => ({
      width: adWidth,
      height,
      ...style,
    }),
    [adWidth, height, style]
  );

  // Stable callbacks using useCallback to prevent re-renders
  const handleError = useCallback(
    (e: any) => {
      onAdError?.(e.nativeEvent);
    },
    [onAdError]
  );

  const handleClick = useCallback(
    (e: any) => {
      onAdClick?.(e.nativeEvent);
    },
    [onAdClick]
  );

  const handleClose = useCallback(
    (e: any) => {
      setClosed(true);
      onAdClose?.(e.nativeEvent);
    },
    [onAdClose]
  );

  const handleLayout = useCallback(
    (e: any) => {
      const newHeight = e.nativeEvent.height;
      if (newHeight && !heightInitialized.current) {
        setHeight(newHeight + 10);
        heightInitialized.current = true;
      }
      onAdLayout?.(e.nativeEvent);
    },
    [onAdLayout]
  );

  // Early returns after all hooks
  if (!visible || closed) {
    return null;
  }

  const NativeComponent = getFeedAdComponent();

  if (!NativeComponent) {
    throw new Error(LINKING_ERROR);
  }

  return (
    <NativeComponent
      codeid={codeid}
      // 里面素材的宽度，减30是有些情况下，里面素材过宽贴边显示不全
      adWidth={adWidth - 30}
      // 为了不影响广告宽度占满屏幕的情况，style的width可单独控制
      style={containerStyle}
      onAdError={handleError}
      onAdClick={handleClick}
      onAdClose={handleClose}
      onAdLayout={handleLayout}
    />
  );
};

export default React.memo(FeedAdView, (prevProps, nextProps) => {
  // Custom comparison function for React.memo
  // Only re-render if visible changes or key props change
  return (
    prevProps.codeid === nextProps.codeid &&
    prevProps.visible === nextProps.visible &&
    prevProps.adWidth === nextProps.adWidth
  );
});
