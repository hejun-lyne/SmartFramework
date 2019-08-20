//
//  SFContext.m
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFContext.h"
#import "SFComponent.h"
#import "SFProxy.h"

#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/ldsyms.h>

#pragma mark __DATA Reader

static char* kComponentSectionName = "STComponent";

NSArray<NSString *>* ATHReadSectionData(char *sectionName,const struct mach_header *mhp)
{
    NSMutableArray *configs = [NSMutableArray array];
    unsigned long size = 0;
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
        if(str) [configs addObject:str];
    }
    
    return configs;
}


static void _breakupSectionData(char *secName, const struct mach_header *mhp, void(^iterationBlock)(NSArray *parts))
{
    NSArray <NSString *> *strings = ATHReadSectionData(secName, mhp);
    if (strings.count > 0) {
        for (NSString *str in strings) {
            NSArray *parts = [str componentsSeparatedByString:@"#"];
            iterationBlock(parts);
        }
    }
}

static void ath_onloaded(const struct mach_header *mhp, intptr_t vmaddr_slide)
{
    _breakupSectionData(kComponentSectionName, mhp, ^(NSArray *parts) {
        Class clazz = NSClassFromString(parts[0]);
        if (clazz == nil) {
            return;
        }
        Protocol *proto = NSProtocolFromString(parts[1]);
        if (proto == nil) {
            return;
        }
        SFComponent *comp = [[SFComponent alloc] initWithClass:clazz proto:proto];
        BOOL onLoad = [parts[2] isEqualToString:@"OnLoad"];
        NSUInteger priority = [parts[3] unsignedIntegerValue];
        comp.onLoad = onLoad;
        comp.priority = priority;
    });
}

__attribute__((constructor))
void initProphet()
{
    _dyld_register_func_for_add_image(ath_onloaded);
}

#pragma mark - SFContext

static void *const GlobalConntextQueueIdentityKey = (void *)&GlobalConntextQueueIdentityKey;
static dispatch_queue_t contextQueue;

static inline void SYNC_EXECUTE_IN_QUEUE(dispatch_block_t block) {
    if (dispatch_get_specific(GlobalConntextQueueIdentityKey)) {
        block();
    } else {
        dispatch_sync(contextQueue, block);
    }
}
static inline void ASYNC_EXECUTE_IN_QUEUE(dispatch_block_t block) {
    dispatch_async(contextQueue, block);
}

@implementation SFContext
{
    NSMutableDictionary *_globalDictionary;
}

+ (void)initialize
{
    contextQueue = dispatch_queue_create("smartframework.context", NULL);
    void *nonNullValue = GlobalConntextQueueIdentityKey;
    dispatch_queue_set_specific(contextQueue, GlobalConntextQueueIdentityKey, nonNullValue, NULL);
}

+ (instancetype)shared
{
    static SFContext *s_context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_context = [SFContext new];
    });
    return s_context;
}

+ (void)initWithLaunchOptions:(NSDictionary *)launchOptions
{
    SFContext *context = [self shared];
    context->_launchOptions = launchOptions;
    [context onInit];
}

+ (void)setGlobalValue:(id)value forKey:(NSString *)key
{
    SFContext *context = [self shared];
    SYNC_EXECUTE_IN_QUEUE(^{
        if (!context->_globalDictionary) {
            context->_globalDictionary = [NSMutableDictionary new];
        }
        [context->_globalDictionary setObject:value forKey:key];
    });
}

+ (id)executorFor:(Protocol *)protocol allowDelay:(BOOL)allowDelay
{
    SFComponent *comp = SFComponentForProtocol(protocol);
    if (comp == nil) {
#if DEBUG
         NSAssert(NO, @"No known component is implementing [%@]", protocol);
#else
        return nil;
#endif
    }
    
    if (!comp.onLoad) {
        // on needed, create instance
        return [comp getOrCreateInstance];
    }
    if (!allowDelay) {
        // check instance
        return [comp getInstance];
    }
    
    return [[SFProxy alloc] initWithComponent:comp];
}

- (NSDictionary *)globalDictionary
{
    __block NSDictionary *dict;
    SYNC_EXECUTE_IN_QUEUE(^{
        dict = self->_globalDictionary.copy;
    });
    return dict;
}

- (void)onInit
{
    // Initialize 'OnLoad' components
    NSArray<SFComponent *> *onLoadComps = AllOnLoadSFComponents();
    // sort base on priority
    [onLoadComps sortedArrayUsingComparator:^NSComparisonResult(SFComponent*  _Nonnull obj1, SFComponent*  _Nonnull obj2) {
        if (obj1.priority > obj2.priority) {
            return NSOrderedDescending;
        } else if (obj1.priority < obj2.priority) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
    // perform create
    [onLoadComps makeObjectsPerformSelector:@selector(getOrCreateInstance)];
    // flush proxies
    ASYNC_EXECUTE_IN_QUEUE(^{
        for (SFComponent *comp in onLoadComps) {
            NSArray<SFProxy *> *proxies = PopSFProxiesForProtocol(comp.proto);
            [proxies makeObjectsPerformSelector:@selector(execute)];
        }
    });
}


@end
