//
//  SFComponent.m
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFComponent.h"

#import <objc/runtime.h>

@interface NSObject (AutoBind)

+ (instancetype)alloc_sf;

@end

static NSLock *s_comp_lock;
static NSMutableDictionary *s_components;
static NSMutableDictionary *s_classToProtocols;

NSArray<SFComponent *> *AllOnLoadSFComponents() {
    NSMutableArray *result = [NSMutableArray array];
    [s_comp_lock lock];
    NSArray *candidates = s_components.allValues;
    [s_comp_lock unlock];
    for (SFComponent *comp in candidates) {
        if (!comp.onLoad) {
            continue;
        }
        [result addObject:comp];
    }
    return result;
}

SFComponent *SFComponentForProtocol(Protocol *proto) {
    NSString *key = NSStringFromProtocol(proto);
    id result = nil;
    [s_comp_lock lock];
    result = [s_components objectForKey:key];
    [s_comp_lock unlock];
    return result;
}

@interface SFComponent()
@property (nonatomic, weak) id weakInstance;
@property (nonatomic, strong) id strongInstance;
@end
@implementation SFComponent

+ (void)initialize
{
    s_comp_lock = [NSLock new];
    s_components = [NSMutableDictionary dictionary];
    s_classToProtocols = [NSMutableDictionary dictionary];
}

- (instancetype)initWithClass:(Class)clazz proto:(Protocol *)proto
{
    if (self = [super init]) {
        _clazz = clazz;
        NSString *clsName = NSStringFromClass(clazz);
        NSString *protoName = NSStringFromProtocol(proto);
        [s_comp_lock lock];
        [s_classToProtocols setObject:protoName forKey:clsName];
        [s_components setObject:self forKey:protoName];
        [s_comp_lock unlock];
    }
    return self;
}

- (void)setupBinding
{
    if (self.clazz == nil) {
        return;
    }
    Method originalMethod = class_getClassMethod(self.clazz, @selector(alloc));
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);
    Method replacementMethod = class_getClassMethod(object_getClass(self.clazz), @selector(alloc_sf));
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);
    if (class_addMethod(object_getClass(self.clazz), @selector(alloc), replacementImplementation, replacementArgTypes)){
        class_replaceMethod(object_getClass(self.clazz), @selector(alloc_sf), originalImplementation, originalArgTypes);
    }
}

- (id)getInstance
{
    if (self.weakInstance != nil) {
        return self.weakInstance;
    }
    if (self.strongInstance != nil) {
        return self.strongInstance;
    }
    
    return nil;
}

- (id)getOrCreateInstance
{
    id instance = [self getInstance];
    if (instance == nil) {
        // create strong instance.
        instance = [[self.clazz alloc] init];
        _strongInstance = instance;
    }
    return instance;
}

@end

@implementation NSObject (AutoBind)

+ (instancetype)alloc_sf
{
    id obj = [self alloc_sf];
    if (obj) {
        NSString *className = NSStringFromClass(self.class);
        [s_comp_lock lock];
        NSString *key = [s_classToProtocols objectForKey:className];
        SFComponent *comp = [s_components objectForKey:key];
        [s_comp_lock unlock];
        comp.weakInstance = obj;
    }
    return obj;
}

@end

