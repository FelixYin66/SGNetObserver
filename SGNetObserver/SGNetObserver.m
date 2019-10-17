//
//  SGNetObserver.m
//  SGNetObserverDemo
//
//  Created by apple on 16/9/19.
//  Copyright © 2016年 iOSSinger. All rights reserved.
//

#import "SGNetObserver.h"
#import "Reachability.h"
#import "SimplePinger.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

NSString *SGReachabilityChangedNotification = @"SGNetworkReachabilityChangedNotification";

@interface SGNetObserver()

@property (nonatomic,copy) NSString *host;
@property(nonatomic,copy) NSString *openURL;

@property (nonatomic,strong) Reachability *hostReachability;

@property (nonatomic,strong) SimplePinger *pinger;
@end

@implementation SGNetObserver

//    MARK:  - 初始化

+ (instancetype)defultObsever{
    SGNetObserver *obsever = [[self alloc] init];
    obsever.host = @"www.baidu.com";
    obsever.openURL = @"https://www.baidu.com";
    return obsever;
}

+ (instancetype)observerWithHost:(NSString *)host openURL:(NSString *)openURL{
    SGNetObserver *obsever = [[self alloc] init];
    obsever.host = host;
    obsever.openURL = openURL;
    return obsever;
}

- (instancetype)init{
    if (self = [super init]) {
        _networkStatus = -1;
        _failureTimes = 2;
        _interval = 1.0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void) enterBackground{
    [self stopNotifier];
}

- (void) becomeActive{
    [self startNotifier];
}

- (void)dealloc{
    [self.hostReachability stopNotifier];
    [self.pinger stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

//    MARK:  - function

- (void)startNotifier{
    [self.hostReachability startNotifier];
    [self.pinger startNotifier];
}

- (void)stopNotifier{
    [self.hostReachability stopNotifier];
    [self.pinger stopNotifier];
}

- (BOOL)checkNetCanUse {
    __block BOOL canUse = NO;
    NSString *urlString = self.openURL;
    // 使用信号量实现NSURLSession同步请求
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        if (res.statusCode == 200 && !error) {
             self.urlCanOpen = YES;
            NSLog(@"手机所连接的网络是可以访问互联网的");
        }else{
            self.urlCanOpen = NO;
            NSLog(@"手机无法访问互联网");
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return canUse;
}


//    MARK: - delegate

- (void)networkStatusDidChanged{
    //获取两种方法得到的联网状态,并转为BOOL值
    BOOL status1 = [self.hostReachability currentReachabilityStatus];
    BOOL status2 =  self.pinger.reachable;
    self.urlCanOpen = [self checkNetCanUse];
    //综合判断网络,判断原则:Reachability -> pinger
    if ((status1 && status2) || (status1 && self.urlCanOpen)) {
        //有网
        self.networkStatus = self.netWorkDetailStatus;
    }else{
        //无网
        self.networkStatus = SGNetworkStatusNone;
    }
}

//    MARK:  - setter

- (void)setNetworkStatus:(SGNetworkStatus)networkStatus{
    if (_networkStatus != networkStatus) {
        _networkStatus = networkStatus;
        //有代理
        if(self.delegate){//调用代理
            if ([self.delegate respondsToSelector:@selector(observer:host:networkStatusDidChanged:)]) {
                [self.delegate observer:self host:self.host networkStatusDidChanged:networkStatus];
            }
        }else{//发送全局通知
            NSDictionary *info = @{@"status" : @(networkStatus),
                                   @"host"   : self.host      };
            [[NSNotificationCenter defaultCenter] postNotificationName:SGReachabilityChangedNotification object:nil userInfo:info];
        }
    }
    
}

//    MARK: - getter

- (Reachability *)hostReachability{
    if (_hostReachability == nil) {
        _hostReachability = [Reachability reachabilityWithHostName:self.host];
        
        __weak typeof(self) weakSelf = self;
        [_hostReachability setNetworkStatusDidChanged:^{
            [weakSelf networkStatusDidChanged];
        }];
    }
    return _hostReachability;
}

- (SimplePinger *)pinger{
    if (_pinger == nil) {
        _pinger = [SimplePinger simplePingerWithHostName:self.host];
        _pinger.supportIPv4 = self.supportIPv4;
        _pinger.supportIPv6 = self.supportIPv6;
        _pinger.interval = self.interval;
        _pinger.failureTimes = self.failureTimes;
        
        __weak typeof(self) weakSelf = self;
        [_pinger setNetworkStatusDidChanged:^{
            [weakSelf networkStatusDidChanged];
        }];
    }
    return _pinger;
}

//    MARK:  - tools

- (SGNetworkStatus)netWorkDetailStatus{
    SGNetworkStatus status = SGNetworkStatusNone;
    if (self.hostReachability.currentReachabilityStatus == ReachableViaWiFi) {
        status = SGNetworkStatusWifi;
    }else if (self.hostReachability.currentReachabilityStatus == ReachableViaWWAN){
        CTTelephonyNetworkInfo *info = [CTTelephonyNetworkInfo new];
        if ([info respondsToSelector:@selector(currentRadioAccessTechnology)]) {
            NSString *currentStatus = info.currentRadioAccessTechnology;
            NSArray *network2G = @[CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x];
            NSArray *network3G = @[CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB, CTRadioAccessTechnologyeHRPD];
            NSArray *network4G = @[CTRadioAccessTechnologyLTE];
            if ([network2G containsObject:currentStatus]) {
                status = SGNetworkStatus2G;
            }else if ([network3G containsObject:currentStatus]) {
                status = SGNetworkStatus3G;
            }else if ([network4G containsObject:currentStatus]){
                status = SGNetworkStatus4G;
            }else {
                status = SGNetworkStatusUkonow;
            }
        }
    }
    return status;
}

- (NSDictionary *)networkDict{
    return @{
             @(SGNetworkStatusNone)   : @"无网络",
             @(SGNetworkStatusUkonow) : @"未知网络",
             @(SGNetworkStatus2G)     : @"3G网络",
             @(SGNetworkStatus3G)     : @"3G网络",
             @(SGNetworkStatus4G)     : @"4G网络",
             @(SGNetworkStatusWifi)   : @"WIFI网络",
            };
}
@end
