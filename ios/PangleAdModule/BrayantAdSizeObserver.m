#import "BrayantAdSizeObserver.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@class BrayantAdSizeObserver;

@interface BrayantAdSizeObserverTarget : NSObject
@property(nonatomic, weak) BrayantAdSizeObserver *observer;
- (void)tick:(CADisplayLink *)displayLink;
@end

@interface BrayantAdSizeObserver ()
@property(nonatomic, weak) UIView *view;
@property(nonatomic, copy) void (^onSizeChange)(CGSize size);
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) CGSize lastSize;
@end

@implementation BrayantAdSizeObserverTarget
- (void)tick:(CADisplayLink *)displayLink {
  BrayantAdSizeObserver *observer = self.observer;
  if (!observer) {
    [displayLink invalidate];
    return;
  }
  [observer checkForSizeChange];
}
@end

@implementation BrayantAdSizeObserver

- (instancetype)initWithView:(UIView *)view
               onSizeChange:(void (^)(CGSize))onSizeChange {
  self = [super init];
  if (self) {
    _view = view;
    _onSizeChange = [onSizeChange copy];
    _lastSize = CGSizeZero;
  }
  return self;
}

- (void)start {
  if (self.displayLink || !self.view.window) {
    return;
  }
  BrayantAdSizeObserverTarget *target = [BrayantAdSizeObserverTarget new];
  target.observer = self;
  self.displayLink = [CADisplayLink displayLinkWithTarget:target selector:@selector(tick:)];
  self.displayLink.preferredFramesPerSecond = 15;
  [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
  [self checkForSizeChange];
}

- (void)checkForSizeChange {
  UIView *view = self.view;
  if (!view.window) {
    [self stop];
    return;
  }
  for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
    if (ancestor.hidden || ancestor.alpha <= 0) {
      return;
    }
  }
  [view layoutIfNeeded];
  CGSize size = view.bounds.size;
  if (!isfinite(size.width) || !isfinite(size.height) ||
      size.width <= 0 || size.height <= 0 || CGSizeEqualToSize(size, self.lastSize)) {
    return;
  }
  self.lastSize = size;
  self.onSizeChange(size);
}

- (void)stop {
  [self.displayLink invalidate];
  self.displayLink = nil;
}

- (void)dealloc {
  [_displayLink invalidate];
}
@end
