//
//  SFEvent.m
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFEvent.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface SFEvent (Private)
+ (instancetype)shared;
- (NSPointerArray *)targetsForEvent:(id)event;
@end

#pragma mark - Custom Block

//Refer https://opensource.apple.com/source/libclosure/libclosure-67 Block_private.h

typedef NS_OPTIONS(int, SFBlockFlag) {
    SFBlockFlagHasCopyDispose        = (1 << 25),
    SFBlockFlagHasSignature          = (1 << 30)
};

struct SF_Block_descriptor_1 {
    uintptr_t reserved;
    uintptr_t size;
};

struct SF_Block_descriptor_2 {
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
};

struct SF_Block_descriptor_3 {
    const char *signature;
    const char *layout;
};

struct SF_Block_layout {
    void *isa;
    volatile int32_t flags;
    int32_t reserved;
    void (*invoke)(void *, ...);
    struct SF_Block_descriptor_1 *descriptor;
};
typedef struct SF_Block_layout  *SFBlockLayout;

static struct SF_Block_descriptor_2 * _SF_Block_descriptor_2(SFBlockLayout aBlock) {
    if (! (aBlock->flags & SFBlockFlagHasCopyDispose)) return NULL;
    uint8_t *desc = (uint8_t *)aBlock->descriptor;
    desc += sizeof(struct SF_Block_descriptor_1);
    return (struct SF_Block_descriptor_2 *)desc;
}

static struct SF_Block_descriptor_3 * _SF_Block_descriptor_3(SFBlockLayout aBlock)
{
    if (! (aBlock->flags & SFBlockFlagHasSignature)) return NULL;
    uint8_t *desc = (uint8_t *)aBlock->descriptor;
    desc += sizeof(struct SF_Block_descriptor_1);
    if (aBlock->flags & SFBlockFlagHasCopyDispose) {
        desc += sizeof(struct SF_Block_descriptor_2);
    }
    return (struct SF_Block_descriptor_3 *)desc;
}

static IMP SF_GetMsgForward(const char *methodTypes) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    if (methodTypes[0] == '{') {
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:methodTypes];
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    }
#endif
    return msgForwardIMP;
}

static void SF_Block_forwardInvocation(id self, SEL _cmd, NSInvocation *invocation) {
    NSPointerArray *targets = [SFEvent.shared targetsForEvent:self];
    for (int i = 0; i < targets.count; i++) {
        void *tar = [targets pointerAtIndex:i];
        if (tar == NULL) {
            continue;
        }
        invocation.target = (__bridge id _Nonnull)(tar);
        [invocation invoke];
    }
}

NSMethodSignature *SF_Block_methodSignatureForSelector(id self, SEL _cmd, SEL aSelector)
{
    struct SF_Block_descriptor_3 *descriptor_3 = _SF_Block_descriptor_3((__bridge void *)self);
    return [NSMethodSignature signatureWithObjCTypes:descriptor_3->signature];
}

static void SF_NSBlock_hook() {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"NSBlock");
        //methodSignature
        {
            SEL selector = @selector(methodSignatureForSelector:);
            Method method = class_getInstanceMethod([NSObject class], selector);
            BOOL success = class_addMethod(cls, selector, (IMP)SF_Block_methodSignatureForSelector, method_getTypeEncoding(method));
            if (!success) {
                class_replaceMethod(cls, selector, (IMP)SF_Block_methodSignatureForSelector, method_getTypeEncoding(method));
            }
        }
        //forwardInvocation
        {
            SEL selector = @selector(forwardInvocation:);
            Method method = class_getInstanceMethod([NSObject class], selector);
            BOOL success = class_addMethod(cls, selector, (IMP)SF_Block_forwardInvocation, method_getTypeEncoding(method));
            if (!success) {
                class_replaceMethod(cls, selector, (IMP)SF_Block_forwardInvocation, method_getTypeEncoding(method));
            }
        }
    });
}

id SF_Block(id obj) {
    SF_NSBlock_hook();
    SFBlockLayout block = (__bridge SFBlockLayout)(obj);
    
    struct SF_Block_descriptor_2 *descriptor_2 = _SF_Block_descriptor_2(block);
    if (descriptor_2) {
        SFBlockLayout newBlock = malloc(block->descriptor->size);
        if (!newBlock)
            return nil;
        memmove(newBlock, block, block->descriptor->size);
        
        struct SF_Block_descriptor_3 *descriptor_3 =  _SF_Block_descriptor_3(block);
        newBlock->invoke = (void *)SF_GetMsgForward(descriptor_3->signature);
        
        id objcBlock = (__bridge id)(newBlock);
        return objcBlock;
    } else {
        SFBlockLayout newBlock = malloc(sizeof(struct SF_Block_layout));
        newBlock->isa = block->isa;
        newBlock->flags = block->flags;
        newBlock->reserved = block->reserved;
        newBlock->descriptor = block->descriptor;
        
        struct SF_Block_descriptor_3 *descriptor_3 =  _SF_Block_descriptor_3(block);
        newBlock->invoke = (void *)SF_GetMsgForward(descriptor_3->signature);
        
        id objcBlock = (__bridge id)(newBlock);
        return objcBlock;
    }
}

#pragma mark - SFEvent

static inline NSString * SFBlockKey(id block) {
    return [NSString stringWithFormat:@"%lu",(unsigned long)[block hash]];
}
static NSLock *s_event_lock;
static NSMutableDictionary *s_eventBlocks;
static NSMutableDictionary *s_eventReceivers;
@implementation SFEvent

+ (instancetype)shared
{
    static SFEvent *s_event = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_event = [SFEvent new];
    });
    return s_event;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        s_event_lock = [NSLock new];
        s_eventBlocks = [NSMutableDictionary dictionary];
        s_eventReceivers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)subscribe:(NSString *)name receiver:(id)receiver eventBlock:(id)block
{
    NSParameterAssert(block);
    NSParameterAssert(name);
    NSParameterAssert(receiver);
    
    [s_event_lock lock];
    
    // check event block
    id eventBlock = [s_eventBlocks objectForKey:name];
    if (eventBlock == nil) {
        eventBlock = SF_Block(block);
        [s_eventBlocks setObject:eventBlock forKey:name];
    }
    
    // add receiver for event
    NSPointerArray *array = [s_eventReceivers objectForKey:SFBlockKey(eventBlock)];
    if (array == nil) {
        array = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsOpaquePersonality];
        [s_eventReceivers setObject:array forKey:name];
    }
    [array addPointer:(__bridge void * _Nonnull)receiver];
    
    [s_event_lock unlock];
}

- (void)unsubscribe:(NSString *)name receiver:(id)receiver
{
    NSParameterAssert(name);
    NSParameterAssert(receiver);
    
    [s_event_lock lock];
    
    id block = [self blockForName:name];
    NSPointerArray *array = [s_eventReceivers objectForKey:SFBlockKey(block)];
    for (int i = 0; i < array.count; i++) {
        void * p = [array pointerAtIndex:i];
        if (p == (__bridge void *)(receiver)) {
            [array removePointerAtIndex:i];
            break;
        }
    }
    
    [s_event_lock unlock];
}

- (id)blockForName:(NSString *)name
{
    id block = nil;
    [s_event_lock lock];
    block = [s_eventBlocks objectForKey:name];
    [s_event_lock unlock];
    return block;
}

- (NSPointerArray *)targetsForEvent:(id)event
{
    NSPointerArray *result;
    [s_event_lock lock];
    NSPointerArray *array = [s_eventReceivers objectForKey:SFBlockKey(event)];
    [array compact];
    result = array.copy;
    [s_event_lock unlock];
    
    return result;
}

+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSString *selectorName = NSStringFromSelector(aSelector);
    if ([selectorName hasPrefix:@"subscribe"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@@"];
    } else if ([selectorName hasPrefix:@"unsubscribe"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }
    return nil;
}

+ (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *selectorName = NSStringFromSelector(anInvocation.selector);
    if ([selectorName hasPrefix:@"subscribe"]) {
        // + (void)subscribe_EVENT_:(id)receiver callback:(_EVENT_)block
        NSRange range1 = [selectorName rangeOfString:@"subscribe"];
        NSRange range2 = [selectorName rangeOfString:@":"];
        if (range1.location == 0 && range2.location > range1.length) {
            NSRange evtNameRange = NSMakeRange(range1.length, range2.location - (range1.location + range1.length));
            // event name
            NSString *evtName = [selectorName substringWithRange:evtNameRange];
            // receiver
            __unsafe_unretained id receiver = nil;
            [anInvocation getArgument:&receiver atIndex:2];
            // block
            __unsafe_unretained id block = nil;
            [anInvocation getArgument:&block atIndex:3];
            [self.shared subscribe:evtName receiver:receiver eventBlock:block];
        }
    } else if ([selectorName hasPrefix:@"unsubscribe"]) {
        // + (void)unsubscribe##_EVENT_:(id)receiver
        NSRange range1 = [selectorName rangeOfString:@"unsubscribe"];
        NSRange range2 = [selectorName rangeOfString:@":"];
        if (range1.location == 0 && range2.location > range1.length) {
            NSRange evtNameRange = NSMakeRange(range1.length, range2.location - (range1.location + range1.length));
            // event name
            NSString *evtName = [selectorName substringWithRange:evtNameRange];
            // receiver
            __unsafe_unretained id receiver = nil;
            [anInvocation getArgument:&receiver atIndex:2];
            
            [self.shared unsubscribe:evtName receiver:receiver];
        }
    }
}


@end
