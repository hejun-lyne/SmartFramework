//
//  SFRouteAction.m
//  SmartFramework
//
//  Created by Li Hejun on 2019/8/21.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "SFRouteAction.h"

@interface SFRouteAction()
@property (nonatomic, copy) SFRouteActionBlock actionBlock;
@end
@implementation SFRouteAction

+ (instancetype)actionWithBlock:(SFRouteActionBlock)block
{
    SFRouteAction *act = [SFRouteAction new];
    act.actionBlock = block;
    return act;
}

- (BOOL)execute:(NSMutableDictionary *)result
{
    if (self.actionBlock == nil) {
        return NO;
    }
    return self.actionBlock(result);
}

@end
