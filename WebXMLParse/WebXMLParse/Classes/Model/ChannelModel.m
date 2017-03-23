//
//  ChannelModel.m
//  WebXMLParse
//
//  Created by alpha on 2017/3/16.
//  Copyright © 2017年 alpha. All rights reserved.
//

#import "ChannelModel.h"

@implementation ChannelModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.channelIconXPathAttributeKey = @"src";
    }
    return self;
}

@end
