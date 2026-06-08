#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdResourceEntry : NSObject

@property(nonatomic, copy) NSString *token;
@property(nonatomic, copy) NSString *requestId;
@property(nonatomic, copy) NSString *format;
@property(nonatomic, copy) NSString *slotId;
@property(nonatomic, assign) double width;
@property(nonatomic, assign) double height;
@property(nonatomic, assign) NSTimeInterval expiresAt;
@property(nonatomic, strong) id resource;

@end

@interface AdResourceStore : NSObject

+ (instancetype)sharedStore;
- (AdResourceEntry *)storeResource:(id)resource
                         requestId:(NSString *)requestId
                            format:(NSString *)format
                            slotId:(NSString *)slotId
                             width:(double)width
                            height:(double)height;
- (nullable AdResourceEntry *)consumeToken:(nullable NSString *)token
                                    format:(NSString *)format
                                    slotId:(NSString *)slotId
                                     width:(double)width
                                    height:(double)height;

@end

NS_ASSUME_NONNULL_END
