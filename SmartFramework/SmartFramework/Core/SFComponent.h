//
//  STComponent.h
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SFComponent;
#if __cplusplus
extern "C" {
#endif
    NSArray<SFComponent *> *AllOnLoadSFComponents();
    SFComponent * SFComponentForProtocol(Protocol *proto);
#if __cplusplus
}
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SFComponent : NSObject
@property (nonatomic, strong) Class clazz;
@property (nonatomic, strong) Protocol *proto;
@property (nonatomic, assign) BOOL onLoad;
@property (nonatomic, assign) NSUInteger priority;

- (instancetype)initWithClass:(Class)clazz proto:(Protocol *)proto;

- (nullable id)getInstance;
- (id)getOrCreateInstance;

- (void)setupBinding;

@end

NS_ASSUME_NONNULL_END
