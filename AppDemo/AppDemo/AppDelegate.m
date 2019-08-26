//
//  AppDelegate.m
//  AppDemo
//
//  Created by Li Hejun on 2019/8/26.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "AppDelegate.h"

#import <smartlogger/SLLogger.h>
#import <smartframework/SFContext.h>
#import <smartsocial/SSContext.h>

@interface AppDelegate ()
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Init SmartFramework
    [SFContext initWithLaunchOptions:launchOptions];
    
    LogError(@"App", @"App finish launch");
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    return [SSContext.shared application:application handleOpenURL:url sourceApplication:nil annotation:nil];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    return [SSContext.shared application:app openURL:url options:options];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    return [SSContext.shared application:application handleOpenURL:url sourceApplication:sourceApplication annotation:annotation];
}

@end
