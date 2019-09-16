//
//  SFProxy.m
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFProxy.h"

static NSLock *s_proxy_lock;
static NSMutableArray<SFProxy *> *s_proxies;

@interface SFProxy()
@property (nonatomic, weak) SFComponent *component;
@property (nonatomic, strong) NSInvocation *invocation;
@property (nonatomic, assign) BOOL inMainQueue;
@end

NSArray<SFProxy *> *PopSFProxiesForProtocol(Protocol *proto) {
    NSMutableArray *result;
    [s_proxy_lock lock];
    for (SFProxy *proxy in s_proxies) {
        if (proxy.component.proto != proto) {
            continue;
        }
        [result addObject:proxy];
    }
    [s_proxies removeObjectsInArray:result];
    [s_proxy_lock unlock];
    return result;
}

@implementation SFProxy

+ (void)initialize
{
    s_proxy_lock = [NSLock new];
    s_proxies = [NSMutableArray array];
}

- (instancetype)initWithComponent:(SFComponent *)component
{
    if (self = [super init]) {
        _component = component;
    }
    return self;
}

- (void)execute
{
    id target = [self.component getInstance];
    if (self.inMainQueue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.invocation invokeWithTarget:target];
        });
    } else {
        [self.invocation invokeWithTarget:target];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.component.clazz instanceMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if (![anInvocation.target isKindOfClass:[SFProxy class]]) {
        [super forwardInvocation:anInvocation];
        return;
    }
    
    const char *returnType = [anInvocation.methodSignature methodReturnType];
    
    NSAssert(returnType[0] == 'v', @"Trying to proxy invoke method (%@),which contains non-void return value! This is not supported, please change it to callback.",NSStringFromSelector(anInvocation.selector));

    NSAssert(self.invocation == nil, @"Invocation already exists! This may happend when you try to assign SF_COMPONENT(someComponentProtocol) to a variable, and send message to it mulitiple times.\
             \
             id component = SF_COMPONENT(IComponentProtocol);\
             [component foo];\
             [component bar];\
             Do not reference the return value of ATH_EXECUTOR, instead, send message to it every time.\
             [SF_COMPONENT(IComponentProtocol) foo];\
             [SF_COMPONENT(IComponentProtocol) bar];\
             ");
    
    if (self.invocation != nil) {
        return;
    }
    [anInvocation retainArguments];
    self.invocation = anInvocation;
    self.inMainQueue = strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0;
    
    // Add to queue
    [s_proxy_lock lock];
    [s_proxies addObject:self];
    [s_proxy_lock unlock];
}

@end
