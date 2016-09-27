//
//  RCTIMModule.m
//  RCTIM
//  网易云信RN登录模块
//  Created by ltjin on 16/9/23.
//  Copyright © 2016年 Yuanyin Guoji. All rights reserved.
//

#import "RCTIMModule.h"
#import "NIMSDK.h"
#import "RCTLog.h"

@interface RCTIMModule()<NIMLoginManagerDelegate>
@end

@implementation RCTIMModule

RCT_EXPORT_MODULE();

//登录方法
// acc登录用户名和密码
// app云信appkey和推送证书名称
RCT_EXPORT_METHOD(login:(NSDictionary *)acc appKey:(NSString *)appKey)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //初始化
        [[NIMSDK sharedSDK] registerWithAppID:appKey cerName:nil];
        [[[NIMSDK sharedSDK] loginManager] addDelegate:self];
        
        //登录
        NIMAutoLoginData *loginData = [[NIMAutoLoginData alloc] init];
        loginData.account = [acc objectForKey:@"accId"];
        loginData.token = [acc objectForKey:@"accToken"];
        RCTLogInfo(@"用户登录信息－用户名：%@, 密码：%@", loginData.account, loginData.token);
        loginData.forcedMode = YES;
        [[[NIMSDK sharedSDK] loginManager] autoLogin:loginData];
    });
}

#pragma mark - NIMLoginManagerDelegate
-(void)onLogin:(NIMLoginStep)step
{
    RCTLogInfo(@"登录回调－%d", step);
}
-(void)onAutoLoginFailed:(NSError *)error
{
    RCTLogInfo(@"登录失败－%@", error);
}

@end
