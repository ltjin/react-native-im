//
//  RCTIM.h
//  RCTIM
//
//  Created by ltjin on 16/9/19.
//  Copyright © 2016年 Yuanyin Guoji. All rights reserved.
//

#import "RCTView.h"
@class AVAudioPlayer;

@interface RCTIM : RCTView

@property (nonatomic,strong) AVAudioPlayer *player; //播放提示音

@property (nonatomic, strong) NSDictionary *callInfo;
@property (nonatomic, strong) NSString *control;
@property (nonatomic, copy) RCTBubblingEventBlock onHangUp;
@property (nonatomic, copy) RCTBubblingEventBlock onConnected;

#pragma mark - Ring
//铃声 - 正在呼叫请稍后
- (void)playConnnetRing;
//铃声 - 对方暂时无法接听
- (void)playHangUpRing;
//铃声 - 对方正在通话中
- (void)playOnCallRing;
//铃声 - 对方无人接听
- (void)playTimeoutRing;
//铃声 - 接收方铃声
- (void)playReceiverRing;
//铃声 - 拨打方铃声
- (void)playSenderRing;

@end
