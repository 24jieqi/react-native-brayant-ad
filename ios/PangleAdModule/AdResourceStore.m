#import "AdResourceStore.h"
#import "BannerAd.h"
#import "ExpressNativeAd.h"
#import "SplashAd.h"
#import <math.h>

@implementation AdResourceEntry
@end

@interface AdResourceStore ()
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, AdResourceEntry *> *entries;
@end

@implementation AdResourceStore

- (void)disposeEntry:(AdResourceEntry *)entry {
  id resource = entry.resource;
  if ([resource isKindOfClass:[BannerAd class]]) {
    [(BannerAd *)resource removeAd];
  } else if ([resource isKindOfClass:[ExpressNativeAd class]]) {
    [(ExpressNativeAd *)resource removeAd];
  } else if ([resource isKindOfClass:[SplashAd class]]) {
    [(SplashAd *)resource removeAd];
  }
}

+ (instancetype)sharedStore {
  static AdResourceStore *store = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    store = [[AdResourceStore alloc] init];
  });
  return store;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _entries = [NSMutableDictionary dictionary];
  }
  return self;
}

- (AdResourceEntry *)storeResource:(id)resource
                         requestId:(NSString *)requestId
                            format:(NSString *)format
                            slotId:(NSString *)slotId
                             width:(double)width
                            height:(double)height {
  @synchronized(self) {
    [self cleanupExpired];
    AdResourceEntry *entry = [[AdResourceEntry alloc] init];
    entry.token = [NSUUID UUID].UUIDString;
    entry.requestId = requestId;
    entry.format = format;
    entry.slotId = slotId;
    entry.width = width;
    entry.height = height;
    entry.expiresAt =
        [NSDate date].timeIntervalSince1970 + (5 * 60);
    entry.resource = resource;
    self.entries[entry.token] = entry;
    return entry;
  }
}

- (AdResourceEntry *)consumeToken:(NSString *)token
                           format:(NSString *)format
                           slotId:(NSString *)slotId
                            width:(double)width
                           height:(double)height {
  if (!token || token.length == 0) {
    return nil;
  }

  @synchronized(self) {
    [self cleanupExpired];
    AdResourceEntry *entry = self.entries[token];
    [self.entries removeObjectForKey:token];
    if (!entry) {
      return nil;
    }

    BOOL matches =
        [entry.format isEqualToString:format] &&
        [entry.slotId isEqualToString:slotId] &&
        (width <= 0 || fabs(entry.width - width) < 0.1) &&
        (height <= 0 || fabs(entry.height - height) < 0.1);
    if (!matches) {
      [self disposeEntry:entry];
      return nil;
    }
    return entry;
  }
}

- (void)cleanupExpired {
  NSTimeInterval now = [NSDate date].timeIntervalSince1970;
  NSArray<NSString *> *tokens = self.entries.allKeys;
  for (NSString *token in tokens) {
    AdResourceEntry *entry = self.entries[token];
    if (entry.expiresAt <= now) {
      [self.entries removeObjectForKey:token];
      [self disposeEntry:entry];
    }
  }
}

@end
