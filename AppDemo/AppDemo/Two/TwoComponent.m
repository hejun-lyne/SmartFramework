//
//  TwoComponent.m
//  AppDemo
//
//  Created by Li Hejun on 2019/8/26.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "TwoComponent.h"
#import "TwoInterfaces.h"

#import <smartframework/SFContext.h>
#import <smartsocial/SSContext.h>

SF_COMPONENT(TwoInterfaces, TwoComponent, OnNeed, 1)

@interface TwoComponent()<TwoInterfaces>
@property (nonatomic, strong) NSString *uuid;
@end
@implementation TwoComponent

+ (instancetype)shared
{
    static TwoComponent *s_two = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_two = [TwoComponent new];
    });
    return s_two;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.uuid = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (void)printIdentifier;
{
    NSLog(@"%@", self.uuid);
}

- (void)showQQLogin
{
    
}

@end
