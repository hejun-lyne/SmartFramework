//
//  OneInterfaces.h
//  AppDemo
//
//  Created by Li Hejun on 2019/8/26.
//  Copyright © 2019 Hejun. All rights reserved.
//

#ifndef OneInterfaces_h
#define OneInterfaces_h

#import <UIKit/UIKit.h>

@protocol OneInterfaces <NSObject>

- (void)showWeiboLogin;
- (void)shareWeiboText:(NSString *)text;

@end

#endif /* OneInterfaces_h */
