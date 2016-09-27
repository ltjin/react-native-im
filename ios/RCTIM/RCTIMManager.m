//
//  RCTIMManager.m
//  RCTIM
//
//  Created by ltjin on 16/9/19.
//  Copyright © 2016年 Yuanyin Guoji. All rights reserved.
//

#import "RCTIMManager.h"
#import "RCTIM.h"

@implementation RCTIMManager

RCT_EXPORT_MODULE()

- (UIView *)view
{
    return [[RCTIM alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(callInfo, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(control, NSString);

@end
