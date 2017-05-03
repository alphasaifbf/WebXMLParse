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
@property (nonatomic, assign) BOOL canSetSamsungChannelIconUrl;
@property (nonatomic, strong) NSArray *updateChannelArr;
@property (nonatomic, strong) NSXMLParser *samsungIconParser;
@property (nonatomic, strong) NSXMLParser *samsungInfoParser;

@end

@implementation ChannelTableViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
//    /html/body/div[5]/div[2]/ul/li/a
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.canSetSamsungChannelIconUrl = NO;
    
    // update数据，有几个渠道，发布之后，都会有新的页面rul（如：联想，百度助手）
    [self updateData];
    
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
    
//    // test
//    ChannelModel *channelModel = [ChannelModel new];
//    channelModel.channelUrl = @"http://www.lenovomm.com/search/index.html?q=%E8%8A%B1%E6%B5%B7%E4%BB%93";
//    channelModel.channelName = @"联想";
//    channelModel.channelIconXPath = @"/html/body/div[4]/div[2]/ul/li/a";
//    channelModel.channelIconXPathAttributeKey = @"href";
////    channelModel.channelVersionXPath = @"//*[@id=\"detailinfo\"]/ul[3]/li[1]";
////    channelModel.channelUpdateTimeXPath = @"//*[@id=\"detailinfo\"]/ul[2]/li";
////    self.channelArr = @[[self.channelArr objectAtIndex:16]];
//    self.channelArr = @[channelModel];
//    // test
//    
//    [self getAllHtmLDataAndParse];
    
    
}

- (void)updateData {
    // 联想乐商店
    ChannelModel *lenovoChannelModel = [ChannelModel new];
    lenovoChannelModel.channelUrl = @"http://www.lenovomm.com/search/index.html?q=%E8%8A%B1%E6%B5%B7%E4%BB%93";
    lenovoChannelModel.channelName = @"联想乐商店";
    lenovoChannelModel.channelUpdateUrlXPath = @"/html/body/div[4]/div[2]/ul/li/a";
    lenovoChannelModel.channelUpdateUrlXPathAttributeKey = @"href";
    
    // 百度助手
    ChannelModel *baiduChannelModel = [ChannelModel new];
    baiduChannelModel.channelUrl = @"http://shouji.baidu.com/s?wd=%E8%8A%B1%E6%B5%B7%E4%BB%93&data_type=app&f=header_all%40input";
    baiduChannelModel.channelName = @"百度手机助手";
    baiduChannelModel.channelUpdateUrlXPath = @"//*[@id=\"doc\"]/div[2]/div/div/ul/li[1]/div/div[1]/a";
    baiduChannelModel.channelUpdateUrlXPathAttributeKey = @"href";
    
    self.updateChannelArr = @[lenovoChannelModel,baiduChannelModel];
    __block int sum = 0;
    for (int i = 0; i < self.updateChannelArr.count; i++) {
        ChannelModel *channelModel = [self.updateChannelArr objectAtIndex:i];
        __weak ChannelModel *weakChannelModel = channelModel;
        __weak typeof(self) weakSelf = self;
        [self.sessionManager GET:channelModel.channelUrl
                      parameters:nil
                        progress:nil
                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                             
                             NSError *error;
                             ONOXMLDocument *document = [ONOXMLDocument HTMLDocumentWithData:responseObject error:&error];
                             // updateUrl
                             if (weakChannelModel.channelUpdateUrlXPath.length > 0) {
                                 ONOXMLElement *postsParentElement= [document firstChildWithXPath:weakChannelModel.channelUpdateUrlXPath];
                                 NSLog(@"updateUrl postsParentElement is :%@",postsParentElement);
                                 
                                 // attribute get value
                                 if (weakChannelModel.channelUpdateUrlXPathAttributeKey.length > 0) {
                                     NSDictionary *dic = postsParentElement.attributes;
                                     weakChannelModel.channelUpdateUrl =
                                     [dic objectForKey:weakChannelModel.channelUpdateUrlXPathAttributeKey];
                                 }else {
                                     if (postsParentElement.stringValue.length > 0) {
                                         weakChannelModel.channelUpdateUrl = postsParentElement.stringValue;
                                     }
                                 }
                             }
                             
                             // http prefix
                             if (weakChannelModel.channelUpdateUrl.length > 0 && [weakChannelModel.channelUpdateUrl rangeOfString:@"http"].location == NSNotFound) {
                                 NSURL *url = [NSURL URLWithString:weakChannelModel.channelUrl];
                                 weakChannelModel.channelUpdateUrl = [NSString stringWithFormat:@"%@://%@%@",
                                                                      url.scheme,
                                                                      url.host,
                                                                      weakChannelModel.channelUpdateUrl];
                             }
                             sum++;
                             if (sum == weakSelf.updateChannelArr.count) {
                                 [weakSelf getUpdateChannelInfo];
                             }
                         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                             NSLog(@"error is : %@",error);
                         }];
    }
}

- (void)getUpdateChannelInfo {
    // 更新数据
    for (int i = 0; i < self.updateChannelArr.count; i++) {
        ChannelModel *updateChannelModel = [self.updateChannelArr objectAtIndex:i];
        for (int j = 0; j < self.channelArr.count; j++) {
            ChannelModel *channelModel = [self.channelArr objectAtIndex:j];
            if ([updateChannelModel.channelName isEqualToString:channelModel.channelName]) {
                if (![updateChannelModel.channelUpdateUrl isEqualToString:channelModel.channelUrl]) {
                    // 需要更新
                    channelModel.channelUrl = updateChannelModel.channelUpdateUrl;
                }
            }
        }
    }
    
    [self getAllHtmLDataAndParse];
}

- (void)getAllHtmLDataAndParse {
    for (int i = 0; i < self.channelArr.count; i++) {
        ChannelModel *channelModel = [self.channelArr objectAtIndex:i];
        // samsung post XML and parse XML
        if ([channelModel.channelName isEqualToString:@"三星"]) {
            // 通过搜索接口获取icon数据
            [self updateSamsungIconUrl:channelModel];
            // 通过主页获取version和update time数据
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
                                 
//                                 [document XPath:weakChannelModel.channelIconXPath];
                                 
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

// update samsung icon url data
- (void)updateSamsungIconUrl:(ChannelModel *)channelModel {
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
    [postBody appendData:[[NSString stringWithFormat:@"<SamsungProtocol networkType=\"0\" version2=\"3\" lang=\"EN\" openApiVersion=\"23\" deviceModel=\"SM-G9006W\" mcc=\"460\" mnc=\"00\" csc=\"CHU\" sdlVersion=\"2301\" odcVersion=\"4.2.10-11\" version=\"5.5\" filter=\"1\">"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // app detail
    [postBody appendData:[[NSString stringWithFormat:@"<request name=\"searchProductListEx2Notc\" id=\"2040\" numParam=\"11\" transactionId=\"32c1d224102\">"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"srchClickURL\" />"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"startNum\">1</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"imgHeight\">135</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"qlInputMethod\">ac</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"imgWidth\">135</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"endNum\">30</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"keyword\">&#33457;&#28023;&#20179;</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"contentType\">all</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"qlDomainCode\">sa</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"qlDeviceType\">phone</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"<param name=\"alignOrder\">bestMatch</param>"] dataUsingEncoding:NSUTF8StringEncoding]];
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
                                          weakSelf.samsungIconParser = [[NSXMLParser alloc] initWithData:data];
                                          [weakSelf.samsungIconParser setDelegate:weakSelf];
                                          [weakSelf.samsungIconParser parse];
                                      }];
    [dataTask resume];
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
                                          weakSelf.samsungInfoParser = [[NSXMLParser alloc] initWithData:data];
                                          [weakSelf.samsungInfoParser setDelegate:weakSelf];
                                          [weakSelf.samsungInfoParser parse];
                                      }];
    [dataTask resume];
}

#pragma mark - NSXMLParserDelegate
-(void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"parserDidStartDocument");
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict{
    NSLog(@"didStartElement :elementName:%@,namespaceURI:%@,qualifiedName:%@,attributeDict:%@",
          elementName,namespaceURI,qName,attributeDict);
    NSString *name = [attributeDict objectForKey:@"name"];
    if ([name isEqualToString:@"version"] ||
        [name isEqualToString:@"lastUpdateDate"] ||
        [name isEqualToString:@"productID"] ||
        [name isEqualToString:@"productImgUrl"]) {
        self.cur_elementName = name;
    }else {
        self.cur_elementName = nil;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSLog(@"Characters :%@",string);
    
    // 解析 channel icon
    if (self.samsungIconParser == parser) {
        if ([self.cur_elementName isEqualToString:@"productID"]) {
            if ([string isEqualToString:self.samsungChannelModel.productID]) {
                self.canSetSamsungChannelIconUrl = YES;
            }
        }else if ([self.cur_elementName isEqualToString:@"productImgUrl"]) {
            if (self.canSetSamsungChannelIconUrl) {
                self.samsungChannelModel.channelIcon = string;
                self.canSetSamsungChannelIconUrl = NO;
                [self refreshWithChannel:self.samsungChannelModel];
            }
        }
    }
    
    // 解析 channel info
    if (self.samsungInfoParser == parser) {
        if ([self.cur_elementName isEqualToString:@"version"]) {
            self.samsungChannelModel.channelVerison = string;
            [self refreshWithChannel:self.samsungChannelModel];
        }else if ([self.cur_elementName isEqualToString:@"lastUpdateDate"]) {
            self.samsungChannelModel.channelUpdateTime = string;
            [self refreshWithChannel:self.samsungChannelModel];
        }
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
