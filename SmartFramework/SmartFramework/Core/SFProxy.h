//
//  SFProxy.h
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/20.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFComponent.h"

@class SFProxy;
#if __cplusplus
extern "C" {
#endif
    NSArray<SFProxy *> *PopSFProxiesForProtocol(Protocol *proto);
#if __cplusplus
}
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SFProxy : NSObject

- (instancetype)initWithComponent:(SFComponent *)component;
- (void)execute;

@end

NS_ASSUME_NONNULL_END
