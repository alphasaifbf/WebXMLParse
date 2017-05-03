//
//  ChannelModel.h
//  WebXMLParse
//
//  Created by alpha on 2017/3/16.
//  Copyright © 2017年 alpha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYModel.h"

@interface ChannelModel : NSObject

@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, copy) NSString *channelUrl;
@property (nonatomic, copy) NSString *channelIconXPath;
// (默认 src)找到XPath后，可以还需要attribute才可以准确得到结果
@property (nonatomic, copy) NSString *channelIconXPathAttributeKey;
@property (nonatomic, copy) NSString *channelVersionXPath;
// 找到XPath后，可以还需要attribute才可以准确得到结果
@property (nonatomic, copy) NSString *channelVersionXPathAttributeKey;
@property (nonatomic, copy) NSString *channelUpdateTimeXPath;
// 找到XPath后，可以还需要attribute才可以准确得到结果
@property (nonatomic, copy) NSString *channelUpdateTimeXPathAttributeKey;
@property (nonatomic, copy) NSString *channelIcon;
@property (nonatomic, copy) NSString *channelVerison;
@property (nonatomic, copy) NSString *channelUpdateTime;

// 更新的
@property (nonatomic, copy) NSString *channelUpdateUrl;
@property (nonatomic, copy) NSString *channelUpdateUrlXPath;
@property (nonatomic, copy) NSString *channelUpdateUrlXPathAttributeKey;

// samsung 特有的
@property (nonatomic, copy) NSString *productID;

@end
