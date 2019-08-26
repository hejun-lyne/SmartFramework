//
//  TwoComponent.h
//  AppDemo
//
//  Created by Li Hejun on 2019/8/26.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TwoComponent : NSObject

+ (instancetype)shared;

- (void)printIdentifier;

@end

NS_ASSUME_NONNULL_END
