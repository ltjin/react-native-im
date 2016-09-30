//
//  RCTIMModule.m
//  RCTIM
//  网易云信RN登录模块
//  Created by ltjin on 16/9/23.
//  Copyright © 2016年 Yuanyin Guoji. All rights reserved.
//

#import "RCTIMModule.h"
#import "NIMSDK.h"
#import "NIMAVChat.h"
#import "RCTLog.h"
#import "RCTEventDispatcher.h"

@interface RCTIMModule()<NIMLoginManagerDelegate, NIMNetCallManagerDelegate>
@end

@implementation RCTIMModule

@synthesize bridge = _bridge;

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
        [[NIMSDK sharedSDK].netCallManager addDelegate:self];
        
        //登录
        NIMAutoLoginData *loginData = [[NIMAutoLoginData alloc] init];
        loginData.account = [acc objectForKey:@"accId"];
        loginData.token = [acc objectForKey:@"accToken"];
        NSLog(@"用户登录信息－用户名：%@, 密码：%@", loginData.account, loginData.token);
        loginData.forcedMode = YES;
        [[[NIMSDK sharedSDK] loginManager] autoLogin:loginData];
    });
}

#pragma mark - NIMLoginManagerDelegate
-(void)onLogin:(NIMLoginStep)step
{
    NSLog(@"登录回调－%d", step);
}
-(void)onAutoLoginFailed:(NSError *)error
{
    NSLog(@"登录失败－%@", error);
}
-(void)onKick:(NIMKickReason)code clientType:(NIMLoginClientType)clientType
{
    NSString *log = [NSString stringWithFormat:@"您被踢下线了：%d---%d", code, clientType];
    NSLog(@"%@", log);
    [self.bridge.eventDispatcher sendAppEventWithName:@"onKick" body:@{@"code": [NSString stringWithFormat:@"%d", code], @"clientType":[NSString stringWithFormat:@"%d", clientType]}];
}

#pragma mark - NIMLoginManagerDelegate
-(void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallType)type message:(NSString *)extendMessage
{
    NSLog(@"收到通话邀请－%d", callID);
    [self.bridge.eventDispatcher sendAppEventWithName:@"onReceive" body:@{@"callId": [NSString stringWithFormat:@"%ld", callID]}];
}

@end
