//
//  SFEvent.h
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Declare an event
#define SFEvent_Declare(_EVENT_,_PARAMS_) \
typedef void(^_EVENT_) _PARAMS_; \
@interface SFEvent() \
+ (void)subscribe##_EVENT_:(id)receiver callback:(_EVENT_)block;\
+ (void)unsubscribe##_EVENT_:(id)receiver;\
@end

/// Dispatch an event
#define SFEvent_Dispatch(_NAME_ , _PARAMS_) {_NAME_ f = [SFEvent.shared blockForName:@#_NAME_]; if(f) f _PARAMS_;};

NS_ASSUME_NONNULL_BEGIN

@interface SFEvent : NSObject

+ (instancetype)shared;
- (id)blockForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
