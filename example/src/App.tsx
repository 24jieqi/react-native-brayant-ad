import React, { useEffect, useMemo, useState } from 'react';
import {
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {
  createAdRequest,
  initializeAdSdk,
  preloadInterstitialAd,
  preloadRewardedAd,
  requestPermission,
  showInterstitialAd,
  showRewardedAd,
} from 'react-native-brayant-ad';

const APP_ID = '替换为穿山甲 App ID';
const REWARDED_SLOT_ID = '替换为激励视频代码位';
const INTERSTITIAL_SLOT_ID = '替换为新插屏代码位';

export default function App() {
  const [initialized, setInitialized] = useState(false);
  const [message, setMessage] = useState('等待 SDK 初始化');

  const rewardedRequest = useMemo(
    () =>
      createAdRequest({
        format: 'rewarded',
        slotIds: [REWARDED_SLOT_ID],
        scene: 'example-reward',
        reward: {
          userId: 'example-user-001',
          rewardName: '金币',
          rewardAmount: 100,
          extra: JSON.stringify({ orderId: 'example-order-001' }),
        },
      }),
    []
  );

  const interstitialRequest = useMemo(
    () =>
      createAdRequest({
        format: 'interstitial',
        slotIds: [INTERSTITIAL_SLOT_ID],
        scene: 'example-level-complete',
      }),
    []
  );

  useEffect(() => {
    initializeAdSdk({
      appId: APP_ID,
      appName: 'BrayantAd Example',
      debug: __DEV__,
      allowInitialization: true,
    })
      .then(() => {
        requestPermission();
        setInitialized(true);
        setMessage('SDK 初始化完成');
      })
      .catch((error: unknown) => {
        setMessage(`SDK 初始化失败：${String(error)}`);
      });
  }, []);

  const preloadRewarded = async () => {
    try {
      const token = await preloadRewardedAd(rewardedRequest);
      setMessage(`激励视频预加载完成：${token.slotId}`);
    } catch (error) {
      setMessage(`激励视频预加载失败：${String(error)}`);
    }
  };

  const presentRewarded = async () => {
    try {
      const result = await showRewardedAd({
        request: rewardedRequest,
        loadTimeoutMs: 10_000,
        onEvent: (event) => console.log('Rewarded event', event),
      });
      if (result.reward?.valid) {
        // 业务必须依据奖励校验结果发奖，不能只判断广告关闭或视频播放完成。
        setMessage(
          `奖励有效：${result.reward.amount} ${result.reward.name ?? ''}`
        );
        return;
      }
      setMessage(`未获得奖励，广告状态：${result.status}`);
    } catch (error) {
      setMessage(`激励视频调用失败：${String(error)}`);
    }
  };

  const preloadInterstitial = async () => {
    try {
      const token = await preloadInterstitialAd(interstitialRequest);
      setMessage(`新插屏预加载完成：${token.slotId}`);
    } catch (error) {
      setMessage(`新插屏预加载失败：${String(error)}`);
    }
  };

  const presentInterstitial = async () => {
    try {
      const result = await showInterstitialAd({
        request: interstitialRequest,
        loadTimeoutMs: 10_000,
        onEvent: (event) => console.log('Interstitial event', event),
      });
      setMessage(`新插屏结束：${result.status}`);
    } catch (error) {
      setMessage(`新插屏调用失败：${String(error)}`);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.container}>
        <Text style={styles.title}>穿山甲 v2 全屏广告示例</Text>
        <Text style={styles.status}>{message}</Text>
        <View style={styles.group}>
          <ActionButton
            label="预加载激励视频"
            disabled={!initialized}
            onPress={preloadRewarded}
          />
          <ActionButton
            label="展示激励视频"
            disabled={!initialized}
            onPress={presentRewarded}
          />
        </View>
        <View style={styles.group}>
          <ActionButton
            label="预加载新插屏"
            disabled={!initialized}
            onPress={preloadInterstitial}
          />
          <ActionButton
            label="展示新插屏"
            disabled={!initialized}
            onPress={presentInterstitial}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function ActionButton({
  label,
  disabled,
  onPress,
}: {
  label: string;
  disabled: boolean;
  onPress: () => void | Promise<void>;
}) {
  return (
    <Pressable
      disabled={disabled}
      onPress={onPress}
      style={[styles.button, disabled && styles.buttonDisabled]}
    >
      <Text style={styles.buttonText}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#f5f6f8' },
  container: { padding: 24, gap: 20 },
  title: { fontSize: 24, fontWeight: '700', color: '#111827' },
  status: { minHeight: 48, color: '#374151', lineHeight: 22 },
  group: { gap: 12 },
  button: {
    backgroundColor: '#2563eb',
    borderRadius: 10,
    paddingHorizontal: 20,
    paddingVertical: 14,
  },
  buttonDisabled: { opacity: 0.4 },
  buttonText: { color: '#ffffff', fontSize: 16, textAlign: 'center' },
});
