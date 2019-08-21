//
//  SFRouterInterceptor.h
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/21.
//  Copyright © 2019 Hejun. All rights reserved.
//

#ifndef SFRouterInterceptor_h
#define SFRouterInterceptor_h

#import <Foundation/Foundation.h>

#define SF_ROUTE_INTERCEPTOR(clazz) \
char * _sfRouter_##clazz __attribute((used, section("__DATA,SFRoute "))) = ""#clazz"";

@protocol SFRouterInterceptor
@property (nonatomic, class, readonly) NSUInteger priority;

- (BOOL)interceptURI:(NSString *)uri parameters:(NSDictionary *)parameters;

@end

#endif /* SFRouterInterceptor_h */
