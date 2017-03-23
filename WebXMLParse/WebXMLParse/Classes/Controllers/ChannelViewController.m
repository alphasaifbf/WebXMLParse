//
//  ChannelViewController.m
//  WebXMLParse
//
//  Created by alpha on 2017/3/16.
//  Copyright © 2017年 alpha. All rights reserved.
//

#import "ChannelViewController.h"
#import <WebKit/WebKit.h>

@interface ChannelViewController ()

@end

@implementation ChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    [webView setBackgroundColor:[UIColor grayColor]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.channelUrl]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
