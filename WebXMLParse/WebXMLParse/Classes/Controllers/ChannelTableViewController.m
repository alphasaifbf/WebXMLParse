//
//  ChannelTableViewController.m
//  WebXMLParse
//
//  Created by alpha on 2017/3/16.
//  Copyright © 2017年 alpha. All rights reserved.
//

#import "ChannelTableViewController.h"
#import "ChannelCell.h"
#import "AFNetworking.h"
#import "Ono.h"
#import "ChannelViewController.h"
#import <Foundation/Foundation.h>

@interface ChannelTableViewController () <NSXMLParserDelegate>

@property (nonatomic, strong) NSArray *channelArr;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) ChannelModel *samsungChannelModel;
@property (nonatomic, copy) NSString *cur_elementName;

@end

@implementation ChannelTableViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // read channelinfo.plist
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"channelInfo" ofType:@"plist"];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSArray *arr = [dic objectForKey:@"channelArr"];
    NSMutableArray *channelArr = [NSMutableArray new];
    for (int i = 0; i < arr.count; i++) {
        NSDictionary *info = [arr objectAtIndex:i];
        // dic change to model
        ChannelModel *channelModel = [ChannelModel yy_modelWithDictionary:info];
        
        [channelArr addObject:channelModel];
    }
    self.channelArr = channelArr;
    
    // test
//    ChannelModel *channelModel = [ChannelModel new];
//    channelModel.channelUrl = @"http://store.oppomobile.com/product/0010/881/208_1.html?from=1152_1";
//    channelModel.channelName = @"oppo";
//    channelModel.channelIconXPath = @"//*[@id=\"currentNews\"]/li[1]/img";
//    channelModel.channelVersionXPath = @"//*[@id=\"detailinfo\"]/ul[3]/li[1]";
//    channelModel.channelUpdateTimeXPath = @"//*[@id=\"detailinfo\"]/ul[2]/li";
//    self.channelArr = @[[self.channelArr objectAtIndex:16]];
    // test
    
    [self getAllHtmLDataAndParse];
    
}

- (void)getAllHtmLDataAndParse {
    for (int i = 0; i < self.channelArr.count; i++) {
        ChannelModel *channelModel = [self.channelArr objectAtIndex:i];
        // samsung post XML and parse XML
        if ([channelModel.channelName isEqualToString:@"三星"]) {
            [self samsungXMLParser:channelModel];
        }else {
            __weak ChannelModel *weakChannelModel = channelModel;
            __weak typeof(self) weakSelf = self;
            [self.sessionManager GET:channelModel.channelUrl
                          parameters:nil
                            progress:nil
                             success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                 
                                 NSError *error;
                                 ONOXMLDocument *document = [ONOXMLDocument HTMLDocumentWithData:responseObject error:&error];
                                 
                                 [document XPath:weakChannelModel.channelIconXPath];
                                 
                                 // icon
                                 if (weakChannelModel.channelIconXPath.length > 0) {
                                     ONOXMLElement *postsParentElement= [document firstChildWithXPath:weakChannelModel.channelIconXPath];
                                     NSLog(@"icon postsParentElement is :%@",postsParentElement);
                                     if (postsParentElement.stringValue.length > 0) {
                                         weakChannelModel.channelIcon = postsParentElement.stringValue;
                                     }else {
                                         // attribute get value
                                         if (weakChannelModel.channelIconXPathAttributeKey.length > 0) {
                                             NSDictionary *dic = postsParentElement.attributes;
                                             weakChannelModel.channelIcon =
                                             [dic objectForKey:weakChannelModel.channelIconXPathAttributeKey];
                                         }
                                     }
                                 }
                                 
                                 // version
                                 if (weakChannelModel.channelVersionXPath.length > 0) {
                                     ONOXMLElement *postsParentElement= [document firstChildWithXPath:weakChannelModel.channelVersionXPath];
                                     NSLog(@"version postsParentElement is :%@",postsParentElement);
                                     if (postsParentElement.stringValue.length > 0) {
                                         weakChannelModel.channelVerison = [self strFromat:postsParentElement.stringValue];
                                     }else {
                                         // attribute get value
                                         if (weakChannelModel.channelVersionXPathAttributeKey.length > 0) {
                                             NSDictionary *dic = postsParentElement.attributes;
                                             weakChannelModel.channelVerison =
                                             [self strFromat:[dic objectForKey:weakChannelModel.channelIconXPathAttributeKey]];
                                         }
                                     }
                                 }else {
                                     weakChannelModel.channelVerison = @"nothing";
                                 }
                                 
                                 // update time
                                 if (weakChannelModel.channelUpdateTimeXPath.length > 0) {
                                     ONOXMLElement *postsParentElement= [document firstChildWithXPath:weakChannelModel.channelUpdateTimeXPath];
                                     NSLog(@"time postsParentElement is :%@",postsParentElement);
                                     if (postsParentElement.stringValue.length > 0) {
                                         weakChannelModel.channelUpdateTime = [self strFromat:postsParentElement.stringValue];
                                     }else {
                                         // attribute get value
                                         if (weakChannelModel.channelUpdateTimeXPathAttributeKey.length > 0) {
                                             // 应用宝
                                             NSDictionary *dic = postsParentElement.attributes;
                                             NSString *time = [dic objectForKey:weakChannelModel.channelUpdateTimeXPathAttributeKey];
                                             if (time.length > 0) {
                                                 weakChannelModel.channelUpdateTime =
                                                 [weakSelf dateUTCStringFromTimestamp:time.longLongValue dateFormat:@"yyyy-MM-dd"];
                                             }
                                         }
                                     }
                                 }else {
                                     weakChannelModel.channelUpdateTime = @"nothing";
                                 }
                                 // part refresh
                                 [weakSelf refreshWithChannel:weakChannelModel];
                                 
                             } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                 NSLog(@"error is : %@",error);
                             }];

        }
    }
}

// part refresh
- (void)refreshWithChannel:(ChannelModel *)channelModel {
    NSUInteger index = [self.channelArr indexOfObject:channelModel];
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray *relodPath = @[path];
    [self.tableView reloadRowsAtIndexPaths:relodPath withRowAnimation:UITableViewRowAnimationFade];
}

// del @" " @"\n" @"\n"
- (NSString *)strFromat:(NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    return string;
}

// date format
- (NSString *)dateUTCStringFromTimestamp:(NSTimeInterval)timestamp dateFormat:(NSString *)dateFormat {
    NSString *theDateFormat = @"yyyy-MM-dd HH:mm:ss";
    if (dateFormat) {
        theDateFormat = dateFormat;
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [formatter setTimeZone:sourceTimeZone];
    [formatter setDateFormat:theDateFormat];
    return [formatter stringFromDate:date];
}

// samsung channel parser
- (void)samsungXMLParser:(ChannelModel *)channelModel {
    self.samsungChannelModel = channelModel;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:channelModel.channelUrl]];
    // POST mothod
    [request setHTTPMethod:@"POST"];
    // set headers
    NSString *contentType = [NSString stringWithFormat:@"text/xml"];
    // set Content-Type
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    // create the body
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"<SamsungProtocol networkType=\"0\" version2=\"3\" lang=\"EN\" openApiVersion=\"21\" deviceModel=\"SM-G9006W\" mcc=\"460\" mnc=\"00\" csc=\"CHU\" sdlVersion=\"2101\" odcVersion=\"4.2.04-5\" version=\"5.4\" filter=\"1\">"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // app detail
    [postBody appendData:[[NSString stringWithFormat:@"<request name=\"productDetailOverview\" id=\"2281\" numParam=\"4\" transactionId=\"0\">"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"orderID\" />"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"screenImgWidth\">1080</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"screenImgHeight\">1920</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"productID\">000001214151</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"</request></SamsungProtocol>"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:postBody];
    
    NSString *bodyStr = [[NSString alloc] initWithData:postBody  encoding:NSUTF8StringEncoding];
    NSLog(@"bodyStr: %@ ",bodyStr);
    
    //get response
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:
                                      ^(NSData *data, NSURLResponse *response, NSError *error) {
                                          [weakSelf XMLParserWithData:data];
                                      }];
    [dataTask resume];
}

// parse XML
-(void)XMLParserWithData:(NSData *)data{
    NSXMLParser *XMLParser = [[NSXMLParser alloc] initWithData:data];
    [XMLParser setDelegate:self];
    [XMLParser parse];
}

#pragma mark - NSXMLParserDelegate
-(void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"parserDidStartDocument");
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict{
    NSLog(@"didStartElement :elementName:%@,namespaceURI:%@,qualifiedName:%@,attributeDict:%@",
          elementName,namespaceURI,qName,attributeDict);
    NSString *name = [attributeDict objectForKey:@"name"];
    if ([name isEqualToString:@"version"] || [name isEqualToString:@"lastUpdateDate"]) {
        self.cur_elementName = name;
    }else {
        self.cur_elementName = nil;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSLog(@"Characters :%@",string);
    if ([self.cur_elementName isEqualToString:@"version"]) {
        self.samsungChannelModel.channelVerison = string;
        [self refreshWithChannel:self.samsungChannelModel];
    }else if ([self.cur_elementName isEqualToString:@"lastUpdateDate"]) {
        self.samsungChannelModel.channelUpdateTime = string;
        [self refreshWithChannel:self.samsungChannelModel];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    NSLog(@"didEndElement:elementName:%@,namespaceURI:%@,qName:%@",elementName,namespaceURI,qName);
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    NSLog(@"parserDidEndDocument");
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.channelArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChannelCell"];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ChannelCell" owner:self options:nil] lastObject];
    }
    if (indexPath.row < self.channelArr.count) {
        ChannelModel *channelInfo = [self.channelArr objectAtIndex:indexPath.row];
        [cell refreshView:channelInfo];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.channelArr.count) {
        ChannelModel *channelInfo = [self.channelArr objectAtIndex:indexPath.row];
        if (channelInfo.channelUrl.length > 0) {
            ChannelViewController *channelDetailVC = [ChannelViewController new];
            channelDetailVC.channelUrl = channelInfo.channelUrl;
            channelDetailVC.title = @"Detail";
            [self.navigationController pushViewController:channelDetailVC animated:YES];
        }
    }
}

#pragma mark getting and setting

- (AFHTTPSessionManager *)sessionManager {
    if (_sessionManager == nil) {
        _sessionManager = [AFHTTPSessionManager manager];
        
        // set request serializer
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        // set respone serializer
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        // set time out
        [_sessionManager.requestSerializer setTimeoutInterval:30.0];
        // set user agent
        [_sessionManager.requestSerializer setValue:@"Mozilla/5.0" forHTTPHeaderField:@"User-Agent"];
        
    }
    return _sessionManager;
}

@end
