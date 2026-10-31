#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import "BrayantAdSizeObserver.h"

static NSUInteger assertions = 0;
static void Expect(BOOL condition, NSString *message) {
  assertions++;
  if (!condition) {
    fprintf(stderr, "回归失败：%s\n", message.UTF8String);
    fflush(stderr);
    exit(1);
  }
}

static void Pump(void) {
  // 真实运行 CADisplayLink，不能靠手动 checkForSizeChange 掩盖采样失效。
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:0.35];
  while (deadline.timeIntervalSinceNow > 0) {
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
  }
}

/** 模拟不发送 frame/bounds 自动 KVO 的第三方广告视图。 */
@interface NonKVOAdView : UIView
@property(nonatomic, assign) BOOL invalidBounds;
@end
@implementation NonKVOAdView
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  if ([key isEqualToString:@"frame"] || [key isEqualToString:@"bounds"]) return NO;
  return [super automaticallyNotifiesObserversForKey:key];
}
- (CGRect)bounds {
  // UIKit 不允许将 NaN 直接写入 CALayer，用读取夹具验证生产观察器的有限值保护。
  return self.invalidBounds ? CGRectMake(0, 0, NAN, INFINITY) : [super bounds];
}
@end

static void RunCase(UIWindow *window, Class viewClass, CGFloat width) {
  UIView *holder = [[UIView alloc] initWithFrame:window.bounds];
  [window.rootViewController.view addSubview:holder];
  NonKVOAdView *view = [[viewClass alloc] initWithFrame:CGRectMake(0, 0, width, 120)];
  NSMutableArray<NSValue *> *events = [NSMutableArray new];
  BrayantAdSizeObserver *observer = [[BrayantAdSizeObserver alloc] initWithView:view
    onSizeChange:^(CGSize size) { [events addObject:[NSValue valueWithCGSize:size]]; }];
  [observer start];
  Pump();
  Expect(events.count == 0, @"未挂载的视图不能发出尺寸");
  [holder addSubview:view];
  [observer start];
  [observer start];
  Pump();
  Expect(events.count == 1 && events.lastObject.CGSizeValue.height == 120,
         @"挂载后 start 应上报初始高度且重复 start 不增加事件");

  view.frame = CGRectMake(0, 0, width, 380.2);
  Pump();
  Expect(events.count == 2, @"frame 增高应被持续采样");
  Expect(fabs(events.lastObject.CGSizeValue.height - 380.2) < 0.001,
         @"采样必须保留小数高度");
  view.layer.bounds = CGRectMake(0, 0, width, 160);
  Pump();
  Expect(events.count == 3 && events.lastObject.CGSizeValue.height == 160,
         @"直接修改 layer.bounds 应采样且允许真实收缩");
  Expect(events.lastObject.CGSizeValue.width == width, @"采样必须保留广告宽度");
  [observer checkForSizeChange];
  Pump();
  Expect(events.count == 3, @"相同尺寸不能重复上报");

  view.bounds = CGRectMake(0, 0, width, 0);
  Pump();
  Expect(events.count == 3, @"零高度不能上报");
  view.bounds = CGRectMake(0, 0, 0, 170);
  Pump();
  Expect(events.count == 3, @"零宽度不能上报");
  if ([view isKindOfClass:NonKVOAdView.class]) {
    view.invalidBounds = YES;
    [observer checkForSizeChange];
    Expect(events.count == 3, @"NaN/无穷尺寸不能上报");
    view.invalidBounds = NO;
  }

  view.hidden = YES;
  view.bounds = CGRectMake(0, 0, width, 180);
  Pump();
  Expect(events.count == 3, @"隐藏素材不能发事件");
  view.hidden = NO;
  holder.hidden = YES;
  Pump();
  Expect(events.count == 3, @"隐藏祖先不能发事件");
  holder.hidden = NO;
  holder.alpha = 0;
  Pump();
  Expect(events.count == 3, @"透明祖先不能发事件");
  holder.alpha = 1;
  Pump();
  Expect(events.count == 4 && events.lastObject.CGSizeValue.height == 180,
         @"恢复可见后继续采样");

  [view removeFromSuperview];
  view.bounds = CGRectMake(0, 0, width, 200);
  Pump();
  [observer checkForSizeChange];
  Expect(events.count == 4, @"移除 window 后不能发事件");
  [holder addSubview:view];
  [observer start];
  Pump();
  Expect(events.count == 5 && events.lastObject.CGSizeValue.height == 200,
         @"重新挂载并 start 应恢复采样");
  [observer stop];
  view.bounds = CGRectMake(0, 0, width, 210);
  Pump();
  Expect(events.count == 5, @"stop 应停止持续采样");
  [observer start];
  Pump();
  Expect(events.count == 6, @"显式 stop 后可重新 start");
  [observer stop];

  __weak BrayantAdSizeObserver *weakObserver;
  @autoreleasepool {
    BrayantAdSizeObserver *temporary = [[BrayantAdSizeObserver alloc] initWithView:view
      onSizeChange:^(CGSize size) {}];
    weakObserver = temporary;
    [temporary start];
  }
  Pump();
  Expect(weakObserver == nil, @"CADisplayLink 不能与观察器形成保留循环");
  [holder removeFromSuperview];
}

@interface RegressionDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end
@implementation RegressionDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  self.window.rootViewController = [UIViewController new];
  [self.window makeKeyAndVisible];
  dispatch_async(dispatch_get_main_queue(), ^{
    @try {
      for (NSNumber *width in @[@279, @271]) {
        RunCase(self.window, UIView.class, width.doubleValue);
        RunCase(self.window, NonKVOAdView.class, width.doubleValue);
      }
      printf("BRAYANT_IOS_LAYOUT_PASS：%lu 项 UIKit 断言通过\n", (unsigned long)assertions);
      fflush(stdout);
      exit(0);
    } @catch (NSException *exception) {
      fprintf(stderr, "回归异常：%s\n", exception.description.UTF8String);
      fflush(stderr);
      exit(1);
    }
  });
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 45 * NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{ fprintf(stderr, "回归超时\n"); exit(1); });
  return YES;
}
@end

int main(int argc, char **argv) {
  @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(RegressionDelegate.class)); }
}
