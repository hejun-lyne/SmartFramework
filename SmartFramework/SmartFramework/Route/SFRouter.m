//
//  SFRouter.m
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/21.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFRouter.h"
#import "SFRouteAction.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>

static NSString * const kURIMethodPrefix = @"_UriRoute";

NSString * SFPathOfURI(NSString *uri) {
    NSRange schemeRange = [uri rangeOfString:@"://"];
    if (schemeRange.length) {
        uri = [uri substringFromIndex:schemeRange.location+schemeRange.length];
    }
    NSRange paramRange = [uri rangeOfString:@"?"];
    if (paramRange.length) {
        uri = [uri substringToIndex:paramRange.location];
    }
    NSMutableArray *components = [[uri componentsSeparatedByString:@"/"] mutableCopy];
    NSInteger i = 0;
    while (i < components.count) {
        NSString *content = components[i];
        if (!content.length) {
            [components removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
    NSString *formattedPath = [components componentsJoinedByString:@"/"];
    return formattedPath;
}

NSString * SFSchemeFromURI(NSString *uri) {
    NSRange range = [uri rangeOfString:@"://"];
    if (range.length) {
        return [uri substringToIndex:range.location];
    }
    return nil;
}

NSMutableDictionary * SFParamsFromURI(NSString *uri) {
    NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
    NSString *parametersString = [[NSURL URLWithString:uri] query];
    if (parametersString && parametersString.length > 0) {
        NSArray *paramStringArr = [parametersString componentsSeparatedByString:@"&"];
        for (NSString *paramString in paramStringArr) {
            NSArray *paramArr = [paramString componentsSeparatedByString:@"="];
            if (paramArr.count > 1) {
                NSString *key = [paramArr objectAtIndex:0];
                NSString *value = [paramArr objectAtIndex:1];
                if (key && value) {
                    [mDict setObject:value forKey:key];
                }
            }
        }
    }
    return mDict;
}

static NSArray<NSString *> *s_route_inteceptors;
static void sf_router_onloaded(const struct mach_header *mhp, intptr_t vmaddr_slide)
{
    NSMutableArray *clazzes = [NSMutableArray array];
    unsigned long size = 0;
    const char *sectionName = "SFRoute";
#ifndef __LP64__
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
#else
    const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
#endif
    
    unsigned long counter = size/sizeof(void*);
    for(int idx = 0; idx < counter; ++idx){
        char *string = (char*)memory[idx];
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        if(str) [clazzes addObject:str];
    }
    s_route_inteceptors = clazzes;
}

__attribute__((constructor))
void initRouteIntecptor()
{
    _dyld_register_func_for_add_image(sf_router_onloaded);
}

@implementation SFRouter
{
    NSString *_scheme;
    NSMutableDictionary *mUriActions;
    NSArray<id<SFRouterInterceptor>> *interceptors;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupScheme];
        [self setupURIs];
        [self setupInteceptors];
        mUriActions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setupInteceptors
{
    if (s_route_inteceptors.count == 0) {
        return;
    }
    NSMutableArray<id<SFRouterInterceptor>> *instances = [NSMutableArray array];
    for (NSString *clazzString in s_route_inteceptors) {
        Class cls = NSClassFromString(clazzString);
        if (cls == nil) {
            continue;
        }
        id ins = [[cls alloc] init];
        if (ins != nil) {
            [instances addObject:ins];
        }
    }
    [instances sortUsingComparator:^NSComparisonResult(id<SFRouterInterceptor> obj1, id<SFRouterInterceptor> obj2) {
        return [obj1 priority] < [obj2 priority] ? NSOrderedAscending : NSOrderedDescending;
    }];
    interceptors = instances.copy;
}

- (void)setupURIs
{
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(self.class, &methodCount);
    if (methods && methodCount > 0) {
        for (unsigned int i = 0; i < methodCount; i++) {
            SEL selector = method_getName(methods[i]);
            NSString *selectorName = NSStringFromSelector(selector);
            if ([selectorName hasPrefix:kURIMethodPrefix]) {
                SEL selector = NSSelectorFromString(selectorName);
                IMP imp = [self methodForSelector:selector];
                void (*func)(id, SEL) = (void *)imp;
                func(self, selector);
            }
        }
    }
    if (methods) {
        free(methods);
    }
}

- (void)setupScheme
{
    // get target name
    NSString *target = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] lowercaseString];
    
    // get url types
    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    for (NSDictionary *dict in urlTypes) {
        NSString *s = dict[@"CFBundleURLSchemes"];
        if ([target caseInsensitiveCompare:s] == NSOrderedSame) {
            _scheme = s;
            break;
        }
    }
}

- (void)registerAction:(SFRouteActionBlock)block forURIs:(NSArray<NSString *> *)uris
{
    [uris enumerateObjectsUsingBlock:^(NSString * _Nonnull uri, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = SFPathOfURI(uri);
        SFRouteAction *action = [SFRouteAction actionWithBlock:block];
        @synchronized (self->mUriActions) {
            NSMutableArray<SFRouteAction *> *actions = self->mUriActions[path];
            if (actions == nil) {
                actions = [NSMutableArray arrayWithObject:action];
                self->mUriActions[path] = actions;
            } else {
                [actions addObject:action];
            }
        }
    }];
}

- (BOOL)isURIRegistered:(NSString *)uri
{
    return [self actionsForURI:uri] != nil;
}

- (NSArray<SFRouteAction *> *)actionsForURI:(NSString *)uri
{
    NSArray *result;
    NSString *path = SFPathOfURI(uri);
    @synchronized (self->mUriActions) {
        result = [self->mUriActions objectForKey:path];
    }
    return result;
}

- (id<SFRouterInterceptor>)interceptorOfClass:(Class)clazz
{
    __block id result = nil;
    [interceptors enumerateObjectsUsingBlock:^(NSObject<SFRouterInterceptor> *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:clazz]) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (void)openURI:(NSString *)uri
{
    [self openURI:uri parameters:nil];
}

- (void)openURI:(NSString *)uri parameters:(NSDictionary *)parameters
{
    [self openURI:uri parameters:parameters callback:nil];
}

- (void)openURI:(NSString *)uri parameters:(NSDictionary *)parameters callback:(SFRouteCallback)callback
{
    NSAssert(_scheme != nil, @"scheme is nil");
    NSAssert([NSThread isMainThread], @"openURI should be call in main thread!");
    
    NSString *path = SFPathOfURI(uri);
    if (path == nil) {
        NSAssert(path, @"invalid path!");
        return;
    }
    
    if (!callback) {
        callback = ^(BOOL s, NSDictionary *r){};
    }
    
    // check scheme
    NSString *scheme = SFSchemeFromURI(uri);
    if ([scheme caseInsensitiveCompare:_scheme] != NSOrderedSame) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]
                                               options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @(NO)}
                                     completionHandler:^(BOOL success) {
                                         callback(success, nil);
                                     }];
        } else {
            BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];
            callback(success, nil);
        }
        return;
    }
    
    // check interceptors
    BOOL passed = YES;
    for (NSObject<SFRouterInterceptor> *interceptor in interceptors) {
        if ([interceptor respondsToSelector:@selector(interceptURI:parameters:)]) {
            passed = [interceptor interceptURI:uri parameters:parameters];
            if (!passed) {
                break;
            }
        }
    }
    if (!passed) {
        callback(NO, @{@"reason": @"Intercepted"});
        return;
    }
    
    // do action
    NSMutableDictionary *mParams = SFParamsFromURI(uri);
    [mParams addEntriesFromDictionary:parameters];
    NSArray<SFRouteAction *> *actions = [self actionsForURI:uri];
    BOOL success = NO;
    for (SFRouteAction *act in actions) {
        success = [act execute:mParams];
        if (success) {
            break;
        }
    }
    callback(success, mParams.copy);
}

@end
