//
//  OneComponent.m
//  AppDemo
//
//  Created by Li Hejun on 2019/8/26.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "OneComponent.h"
#import "OneInterfaces.h"

#import <smartlogger/SLLogger.h>
#import <smartframework/SFContext.h>
#import <smartsocial/SSContext.h>

SF_COMPONENT(OneInterfaces, OneComponent, OnNeed, 1)

@interface OneComponent()<OneInterfaces>
@end
@interface WeiboShareInfo : NSObject<ISSShareInfo>
@end
@implementation WeiboShareInfo
@synthesize title, subTitle, content, url, shareImages, channel, wxMiniProgramObject;
@end
@implementation OneComponent

- (instancetype)init
{
    self = [super init];
    if (self) {
        [SSContext.shared.platformConfiguration setWeiboAppKey:@"1727072384" secret:@"7ca079a7a4c229402193c8fd0c54f304" redirectUrl:@"http://" authPolicy:SSAuthPolicyAll];
    }
    return self;
}

- (void)showWeiboLogin
{
    [SSContext.shared requestAuthForPlatform:SSPlatformSinaWeibo parameters:nil completion:^(id<ISSAuthCredential>  _Nullable credential, NSError * _Nullable error) {
        if (error != nil) {
            LogError(@"OneComponent", @"%@", error);
        } else {
            LogInfo(@"OneComponent", @"success with accessToken: %@", credential.accessToken);
        }
    }];
}

- (void)shareWeiboText:(NSString *)text
{
    WeiboShareInfo *info = [WeiboShareInfo new];
    info.title = text;
    info.shareImages = @[@"https://d13ezvd6yrslxm.cloudfront.net/wp/wp-content/images/justiceleague-trailerbreakdown-batman-lightning-700x376.jpg"];
    [SSContext.shared shareToChannel:SSShareChannelSinaWeibo info:info completion:^(BOOL success, NSError * _Nullable error) {
        if (error != nil) {
            LogError(@"OneComponent", @"%@", error);
        } else {
            LogInfo(@"OneComponent", @"success");
        }
    }];
}

@end
