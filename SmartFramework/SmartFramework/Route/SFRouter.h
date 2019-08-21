//
//  SFRouter.h
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/21.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFRouterInterceptor.h"

#define SFRouteDeclareConcretely(__NAME__,__URILIST__,__paramsAndResult__) \
- (void)_UriRoute##__NAME__ \
{\
    SFRouteActionBlock block = ^BOOL(NSDictionary *paramsAndResult) {\
        [self on##__NAME__##Action:paramsAndResult];\
    };\
    [self registerAction:block forUris:__URILIST__];\
}\
- (BOOL)on##__NAME__##Action:(NSDictionary *)__paramsAndResult__

#define SFRouteDeclare(__NAME__,__URILIST__) URIRegisterConcretely(__NAME__,__URILIST__,paramsAndResult)

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^SFRouteActionBlock)(NSMutableDictionary *paramsAndResult);
typedef void (^SFRouteCallback)(BOOL success, NSDictionary * _Nullable result);

@interface SFRouter : NSObject

- (void)registerAction:(SFRouteActionBlock)block forURIs:(NSArray<NSString *> *)uris;
- (BOOL)isURIRegistered:(NSString *)uri;

- (id<SFRouterInterceptor>)interceptorOfClass:(Class)clazz;

- (void)openURI:(NSString *)uri;
- (void)openURI:(NSString *)uri parameters:(nullable NSDictionary *)parameters;
- (void)openURI:(NSString *)uri parameters:(nullable NSDictionary *)parameters callback:(nullable SFRouteCallback)callback;

@end

NS_ASSUME_NONNULL_END
