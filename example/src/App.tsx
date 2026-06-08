import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View, TouchableOpacity } from 'react-native';
import {
  init,
  startRewardVideo,
  requestPermission,
  dyLoadSplashAd,
  legacy,
  hasPreloadedSplashAd,
  startFullScreenVideo,
  BannerAdView,
} from 'react-native-brayant-ad';

export default function App() {
  const [showBannerView, setShowBannerView] = useState(false);
  const [preloaded, setPreloaded] = useState(false);

  useEffect(() => {
    init({
      appid: '****',
      app: '设备信息',
    })
      .then((res) => {
        console.log(res);
        setShowBannerView(true);
        requestPermission();
        // SDK初始化完成后预加载开屏广告
        preloadSplashAdExample();
      })
      .catch((e) => {
        console.log(e);
      });
  }, []);

  // 预加载开屏广告示例
  const preloadSplashAdExample = async () => {
    try {
      // 在应用启动时预加载开屏广告，避免展示时出现白屏
      const result = await legacy.preloadSplashAd({ codeid: '****' });
      console.log('预加载开屏广告成功:', result);
      setPreloaded(true);
    } catch (error) {
      console.log('预加载开屏广告失败:', error);
    }
  };

  // 检查预加载状态
  const checkPreloadStatus = async () => {
    const status = await hasPreloadedSplashAd();
    console.log('预加载状态:', status);
    setPreloaded(status.hasAd);
  };

  // 开屏广告（已预加载版本）
  const onOpenScren = async () => {
    // 检查是否有预加载的广告
    const status = await hasPreloadedSplashAd();
    if (!status.hasAd) {
      console.log('没有预加载的广告，先进行预加载...');
      await preloadSplashAdExample();
    }

    const splashAd = dyLoadSplashAd({
      codeid: '****',
      anim: 'default',
    });

    splashAd.subscribe('onAdClose', (event) => {
      console.log('广告关闭', event);
    });

    splashAd.subscribe('onAdSkip', (i) => {
      console.log('用户点击跳过监听', i);
    });

    splashAd.subscribe('onAdError', (e) => {
      console.log('开屏加载失败监听', e);
    });

    splashAd.subscribe('onAdClick', (e) => {
      console.log('开屏被用户点击了', e);
    });

    splashAd.subscribe('onAdShow', (e) => {
      console.log('开屏开始展示', e);
    });
  };
  return (
    <View style={styles.container}>
      <BannerAdView
        codeid={'****'}
        adWidth={320}
        adHeight={50}
        visible={showBannerView}
        onAdRenderSuccess={(data: any) => {
          console.log('Banner 广告渲染成功！', data);
        }}
        onAdError={(err: any) => {
          console.log('Banner 广告加载失败！', err);
        }}
        onAdDismiss={(data: any) => {
          console.log('Banner 广告关闭！', data);
        }}
        onAdClick={(val: any) => {
          console.log('Banner 广告被用户点击！', val);
        }}
        onAdShow={(val: any) => {
          console.log('Banner 广告展示', val);
        }}
        onAdDislike={(val: any) => {
          console.log('Banner 用户不感兴趣', val);
        }}
      />
      {/*<FeedAdView*/}
      {/*  codeid={'****'}*/}
      {/*  adWidth={400}*/}
      {/*  visible={showFeedView}*/}
      {/*  onAdLayout={(data: any) => {*/}
      {/*    console.log('Feed 广告加载成功！', data);*/}
      {/*  }}*/}
      {/*  onAdClose={(data: any) => {*/}
      {/*    console.log('Feed 广告关闭！', data);*/}
      {/*  }}*/}
      {/*  onAdError={(err: any) => {*/}
      {/*    console.log('Feed 广告加载失败！', err);*/}
      {/*  }}*/}
      {/*  onAdClick={(val: any) => {*/}
      {/*    console.log('Feed 广告被用户点击！', val);*/}
      {/*  }}*/}
      {/*/>*/}
      <TouchableOpacity
        style={{
          marginVertical: 10,
          paddingHorizontal: 30,
          paddingVertical: 15,
          backgroundColor: '#F96',
          borderRadius: 50,
        }}
        onPress={onOpenScren}
      >
        <Text style={{ textAlign: 'center' }}>
          {' '}
          开屏广告{preloaded ? '(已预加载)' : '(未预加载)'}
        </Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={{
          marginVertical: 10,
          paddingHorizontal: 30,
          paddingVertical: 15,
          backgroundColor: '#69F',
          borderRadius: 50,
        }}
        onPress={checkPreloadStatus}
      >
        <Text style={{ textAlign: 'center' }}> 检查预加载状态</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={{
          marginVertical: 20,
          paddingHorizontal: 30,
          paddingVertical: 15,
          backgroundColor: '#F96',
          borderRadius: 50,
        }}
        onPress={() => {
          let fullVideo = startFullScreenVideo({
            codeid: '****',
          });
          console.log('FullVideoAd rs:', fullVideo);
          fullVideo.result?.then((val: any) => {
            console.log('FullVideoAd rs then val', val);
          });

          fullVideo.subscribe('onAdLoaded' as any, (event) => {
            console.log('广告加载成功监听', event);
          });

          fullVideo.subscribe('onAdError' as any, (event) => {
            console.log('广告加载失败监听', event);
          });

          fullVideo.subscribe('onAdClose' as any, (event) => {
            console.log('广告被关闭监听', event);
          });

          fullVideo.subscribe('onAdClick' as any, (event) => {
            console.log('广告点击查看详情监听', event);
          });
        }}
      >
        <Text style={{ textAlign: 'center' }}> Start 全屏视频广告</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={{
          marginVertical: 20,
          paddingHorizontal: 30,
          paddingVertical: 15,
          backgroundColor: '#F96',
          borderRadius: 50,
        }}
        onPress={() => {
          const rewardVideo = startRewardVideo({
            codeid: '****',
          });

          rewardVideo.result.then((val: any) => {
            console.log('RewardVideo 回调结果', val);
          });

          rewardVideo.subscribe('onAdLoaded' as any, (event) => {
            console.log('广告加载成功监听', event);
          });

          rewardVideo.subscribe('onAdError' as any, (event) => {
            console.log('广告加载失败监听', event);
          });

          rewardVideo.subscribe('onAdClose' as any, (event) => {
            console.log('广告被关闭监听', event);
          });

          rewardVideo.subscribe('onAdClick' as any, (event) => {
            console.log('广告点击查看详情监听', event);
          });
        }}
      >
        <Text style={{ textAlign: 'center' }}> Start RewardVideoAd</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
