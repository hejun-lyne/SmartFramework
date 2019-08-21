//
//  SFRouteAction.h
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/21.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface SFRouteAction : NSObject

+ (instancetype)actionWithBlock:(SFRouteActionBlock)block;
- (BOOL)execute:(NSMutableDictionary *)result;

@end

NS_ASSUME_NONNULL_END
