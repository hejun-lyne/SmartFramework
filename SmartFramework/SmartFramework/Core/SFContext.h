//
//  STContext.h
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * e.g. SF_CONCAT(foo, __FILE__).
 */
#define SF_CONCAT2(A, B) A ## B
#define SF_CONCAT(A, B) SF_CONCAT2(A, B)

/*
 * Get unique string（__LINE__ && __COUNTER__）
 * e.g. ATH_UNIQUE_NAME(login)
 */
#define SF_UNIQUE_STRING(key) SF_CONCAT(key, SF_CONCAT(__LINE__, __COUNTER__))

/**
 * Binding protocol
 * If not using this macro:
 *  char *mUniqueString __attribute((used, section("__DATA,"STComponent" "))) = "ProtoImplClass#Proto#OnNeed#1"
 *  @param _protocol_ Interfaces
 *  @param classname  Implementation
 *  @param type       Init type, OnLoad(creat on load) / OnNeed(create on protocol method called) / OnPassive (create on [-(void)alloc] called)
 *  @param priority   Init priority, Only valid for OnLoad
 */
#define SF_COMPONENT(_protocol_, classname, type, priority) \
char *SF_UNIQUE_STRING(classname) __attribute((used, section("__DATA,SFComponent"))) = ""#classname"#"#_protocol_"#"#type"#"#priority"";

#define SF_EXECUTOR(_protocol_) (id<_protocol_>)[SFContext executorFor:@protocol(_protocol_) allowDelay:YES]
#define SF_EXECUTOR_ASYNC(_protocol_) (id<_protocol_>)[SFContext executorFor:@protocol(_protocol_) allowDelay:NO]

NS_ASSUME_NONNULL_BEGIN

@interface SFContext : NSObject
/// Passing parameters between components
@property (nonatomic, readonly) NSDictionary *globalDictionary;
/// App launch options, from AppDelegate
@property (nonatomic, readonly, nullable) NSDictionary *launchOptions;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Set global value
 */
+ (void)setGlobalValue:(id)value forKey:(NSString *)key;

/**
 * Call in [AppDelegate didFinishLaunchingWithOptions:]
 *
 * Will create components of launch type
 * @param launchOptions from AppDelegate
 */
+ (void)initWithLaunchOptions:(NSDictionary *)launchOptions;

/**
 * Get executor for protocol
 *  @param protocol     Protocol
 *  @param allowDelay   If YES，Will wait for component finishing init (means async).Only for OnLoad type component
 */
+ (id)executorFor:(Protocol *)protocol allowDelay:(BOOL)allowDelay;

@end

NS_ASSUME_NONNULL_END
