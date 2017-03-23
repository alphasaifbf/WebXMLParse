//
//  ChannelCell.m
//  WebXMLParse
//
//  Created by alpha on 2017/3/16.
//  Copyright © 2017年 alpha. All rights reserved.
//

#import "ChannelCell.h"
#import "UIImageView+WebCache.h"

@interface ChannelCell()

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) IBOutlet UILabel *updateTimeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;


@end

@implementation ChannelCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)refreshView:(ChannelModel *)channelInfo {
    [self.nameLabel setText:[NSString stringWithFormat:@"name: %@",channelInfo.channelName]];
    [self.versionLabel setText:[NSString stringWithFormat:@"version: %@",channelInfo.channelVerison]];
    [self.updateTimeLabel setText:[NSString stringWithFormat:@"time : %@",channelInfo.channelUpdateTime]];
    
    // http prefix 
    if (channelInfo.channelIcon.length > 0 && [channelInfo.channelIcon rangeOfString:@"http"].location == NSNotFound) {
        NSURL *url = [NSURL URLWithString:channelInfo.channelUrl];
        channelInfo.channelIcon = [NSString stringWithFormat:@"%@://%@%@",
                                   url.scheme,
                                   url.host,
                                   channelInfo.channelIcon];
    }
    [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:channelInfo.channelIcon]];
}


@end
