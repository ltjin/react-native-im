//
//  RCTIM.m
//  RCTIM
//  网易云信RN通话组件
//  Created by ltjin on 16/9/19.
//  Copyright © 2016年 Yuanyin Guoji. All rights reserved.
//

#import "RCTIM.h"
#import "NIMSDK.h"
#import "NIMAVChat.h"
#import "NTESGLView.h"
#import <AVFoundation/AVFoundation.h>

#define NTESUseGLView

//十秒之后如果还是没有收到对方响应的control字段，则自己发起一个假的control，用来激活铃声并自己先进入房间
#define DelaySelfStartControlTime 10
//激活铃声后无人接听的超时时间
#define NoBodyResponseTimeOut 40

@interface RCTIM()<NIMNetCallManagerDelegate, AVAudioPlayerDelegate>

@property (nonatomic,assign) NIMNetCallCamera cameraType;

@property (nonatomic,assign) BOOL caller;   //是否主叫

@property (nonatomic,assign) UInt64 callId;   //通话ID

@property (nonatomic,strong) CALayer *localVideoLayer;

@property (nonatomic, strong) NTESGLView *remoteGLView;

@property (nonatomic,strong) UIImageView *remoteView;

@end

@implementation RCTIM



- (instancetype)init
{
    if(self = [super init]){
        //添加通话委托
        NSLog(@"初始化.......");
        [[NIMSDK sharedSDK].netCallManager addDelegate:self];
    }
    
    return self;
}

-(void)dealloc
{
    [self hangup:_callId];
    [self.player stop];
    [[NIMSDK sharedSDK].netCallManager removeDelegate:self];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

//呼叫信息
// from 主叫信息
// to 被叫信息
- (void)setCallInfo:(NSDictionary *)callInfo
{
    if (callInfo != _callInfo) {
        _callInfo = callInfo;
    }
    //判断主叫还是被叫
    NSString *currentAcc = [[[NIMSDK sharedSDK] loginManager] currentAccount];
    NSString *fromAcc = [callInfo objectForKey:@"from"];
    NSString *toAcc = [callInfo objectForKey:@"to"];
    NSString *callId = [callInfo objectForKey:@"callId"];
    if(callId){
        _callId = [callId integerValue];
        NSLog(@"邀请－%d", _callId);
    }
    
    NSLog(@"当前登录用户：%@， 主叫用户：%@, 被叫用户：%@", currentAcc, fromAcc, toAcc);
    //主叫发起通话
    if([currentAcc isEqualToString:fromAcc]){
        [self startCall:toAcc];
    }else{
        //被叫收到通话邀请播放铃声
        [self playReceiverRing];
    }
}

//发起通话
-(void)startCall:(NSString *)callee
{
    
    NSArray *callees = [NSArray arrayWithObjects:callee, nil];
    
    [self playConnnetRing];
    [[NIMSDK sharedSDK].netCallManager start:callees type:NIMNetCallTypeVideo option:nil completion:^(NSError *error, UInt64 callID) {
        NSLog(@"发起通话－error: %@, callID: %d", error, callID);
        if (!error) {
            _callId = callID;
            //十秒之后如果还是没有收到对方响应的control字段，则自己发起一个假的control，用来激活铃声并自己先进入房间
            NSTimeInterval delayTime = DelaySelfStartControlTime;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self onControl:callID from:callee type:NIMNetCallControlTypeFeedabck];
            });
        }else{
            if (error) {
                NSLog(@"发起通话失败－%@", error);
            }else{
                //说明在start的过程中把页面关了。。
                [[NIMSDK sharedSDK].netCallManager hangup:callID];
            }
        }
    }];
}

//通话控制
-(void)setControl:(NSString *)control
{
    _control = control;
    [self.player stop];
    if([_control isEqualToString:@"refuse"]){
        [self response:_callId accept:NO];
    }else if([_control isEqualToString:@"accept"]){
        [self response:_callId accept:YES];
    }else if([_control isEqualToString:@"hangup"]){
        [self hangup:_callId];
    }
}

//挂断电话
-(void)hangup:(UInt64 *)callId
{
    NSLog(@"挂断通话: %d", callId);
    [[NIMSDK sharedSDK].netCallManager hangup:callId];
}

//是否接受
-(void)response:(UInt64 *)callId accept:(BOOL)accept
{
    if(accept){
        NSLog(@"接受通话: %d", callId);
    }else{
        NSLog(@"拒绝通话: %d", callId);
    }
    [[NIMSDK sharedSDK].netCallManager response:callId accept:accept option:nil completion:^(NSError * _Nullable error, UInt64 callID) {
        [self.player stop];
        NSString *log = [NSString stringWithFormat:@"同意通话回调: %@", error];
        NSLog(@"Log:%@", log);
    }];
}

#pragma mark - NIMNetCallManagerDelegate
-(void)onCall:(UInt64)callID status:(NIMNetCallStatus)status
{
    switch (status) {
        case NIMNetCallStatusConnect:
            NSLog(@"Log:通话状态>>>>>>>>>>>> 已连接");
            self.onConnected(@{@"status": @YES});
            break;
        case NIMNetCallStatusDisconnect:
            NSLog(@"Log:通话状态>>>>>>>>>>>> 已断开");
            self.onConnected(@{@"status": @NO});
            break;
        default:
            break;
    }
    
}

-(void)onResponse:(UInt64)callID from:(NSString *)callee accepted:(BOOL)accepted
{
    if (!accepted) {
        [self playHangUpRing];
    }else{
        [self.player stop];
    }
    NSString *log = [NSString stringWithFormat:@"%@", accepted ? @"同意":@"拒绝"];
    NSLog(@"Log:是否同意通话回调>>>>>>>>>>>> %@", log);
    self.onConnected(@{@"status": accepted ? @YES : @NO, @"type": @"refuse"});
}

-(void)onHangup:(UInt64)callID by:(NSString *)user
{
    NSLog(@"%@：挂断了电话", user);
    self.onHangUp(@{@"callID": [NSString stringWithFormat:@"%ld", callID], @"user":user});
}

- (void)initRemoteGLView {
    _remoteGLView = [[NTESGLView alloc] initWithFrame:self.bounds];
    [_remoteGLView setContentMode:UIViewContentModeScaleAspectFit];
    [_remoteGLView setBackgroundColor:[UIColor clearColor]];
    _remoteGLView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_remoteGLView];
}

#if defined(NTESUseGLView)
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    NSLog(@"远程画面准备就绪回调>>>>>>>>>>>>>> ");
    if (!_remoteGLView) {
        [self initRemoteGLView];
        [self changeLocalPreview];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    [_remoteGLView render:yuvData width:width height:height];
}
#else
- (void)onRemoteImageReady:(CGImageRef)image{
    NSLog(@"远程图片准备就绪回调>>>>>>>>>>>>>> ");
    if(!_remoteView){
        _remoteView = [[UIImageView alloc] initWithFrame:self.frame];
        _remoteView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_remoteView];
    }
    _remoteView.image = [UIImage imageWithCGImage:image];
}
#endif

-(void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallType)type message:(NSString *)extendMessage
{
    NSLog(@"Log:您有新来电，您有新来电，您有新来电，您有新来电，您有新来电－－－－－ID: %d, from:%@", callID, caller);
    _callId = callID;
}

-(void)onLocalPreviewReady:(CALayer *)layer
{
    NSLog(@"Log:本地视频预览准备就绪>>>>>>>>>>>> ");
    if(!_localVideoLayer){
        layer.frame = self.frame;
        _localVideoLayer = layer;
        [self.layer addSublayer:_localVideoLayer];
    }
}

-(void)changeLocalPreview
{
    if(_localVideoLayer){
        _localVideoLayer.zPosition = 1;
        _localVideoLayer.frame = CGRectMake(10, 30, 130, 200);
    }
}

- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control;{
    NSLog(@"Log: 控制回调>>>>>>> %d", control);
    switch (control) {
        case NIMNetCallControlTypeFeedabck:{
            [self playSenderRing];
            NSTimeInterval delayTime = NoBodyResponseTimeOut;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self playTimeoutRing];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self hangup:callID];
                    self.onHangUp(@{@"callID": [NSString stringWithFormat:@"%ld", callID], @"user":user});
                });
            });
            break;
        }
        case NIMNetCallControlTypeBusyLine: {
            [self playOnCallRing];
            break;
        }
        case NIMNetCallControlTypeStartLocalRecord:
            break;
        case NIMNetCallControlTypeStopLocalRecord:
            break;
        default:
            break;
    }
}

#pragma mark - Ring
//铃声 - 正在呼叫请稍后
- (void)playConnnetRing{
    NSLog(@"正在呼叫请稍后！！！");
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_connect_chat_tip_sender" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 对方暂时无法接听
- (void)playHangUpRing{
    NSLog(@"对方暂时无法接听！！！");
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_HangUp" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 对方正在通话中
- (void)playOnCallRing{
    NSLog(@"对方正在通话中！！！");
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_OnCall" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 对方无人接听
- (void)playTimeoutRing{
    NSLog(@"对方无人接听！！！");
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_onTimer" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 接收方铃声
- (void)playReceiverRing{
    NSLog(@"接收方铃声！！！");
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_receiver" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.player.numberOfLoops = 20;
    [self.player play];
}

//铃声 - 拨打方铃声
- (void)playSenderRing{
    [self.player stop];
    NSLog(@"拨打方铃声！！！");
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_sender" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.player.numberOfLoops = 20;
    [self.player play];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"播放铃声出错。。。。。%@", error);
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"播放铃声结果。。。。。%@", flag?@"成功":@"失败");
}
@end
