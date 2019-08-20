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
 * Delare data section
 * e.g. SF_SECTION(ATH_CONCAT(ATH, __FILE__))
 */
#define SF_SECTION(name) __attribute((used, section("__DATA,"#name" ")))

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
 *  @param type       Init type, OnLoad / OnNeed
 *  @param priority   Init priority, Only valid for OnLoad
 */
#define SF_COMPONENT(_protocol_, classname, type, priority) \
char * SF_UNIQUE_STRING(classname) SF_SECTION("STComponent") = ""#classname"#"#_protocol_"#"#type"#"#priority""; \

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
 *  @param allowDelay   If YES，Will wait for component finishing init (means async).
 */
+ (id)executorFor:(Protocol *)protocol allowDelay:(BOOL)allowDelay;

@end

NS_ASSUME_NONNULL_END
