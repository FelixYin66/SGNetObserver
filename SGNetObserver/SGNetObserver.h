//
//  SGNetObserver.h
//  SGNetObserverDemo
//
//  Created by apple on 16/9/19.
//  Copyright © 2016年 iOSSinger. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  网络状态变化的全局通知
 *  info-keys:
 *  @"status"  网络状态,SGNetworkStatus类型
 *  @"host"    host 地址
 */
extern NSString *SGReachabilityChangedNotification;


typedef NS_ENUM(NSUInteger, SGNetworkStatus) {
    SGNetworkStatusNone = 0,
    SGNetworkStatus2G = 1,
    SGNetworkStatus3G = 2,
    SGNetworkStatus4G = 3,
    SGNetworkStatusWifi = 4,
    SGNetworkStatusUkonow = 5
};

@protocol SGNetworkStatusDelegate <NSObject>

- (void)observer:(id)obsever host:(NSString *)host networkStatusDidChanged:(SGNetworkStatus)ststus;

@end

@interface SGNetObserver : NSObject
/**
 *  当前网络状态
 */
@property (nonatomic,assign) SGNetworkStatus networkStatus;


@property(nonatomic,assign) BOOL urlCanOpen; //检测URL是否可以打开

/**
 * delegate,如果设定,只走代理,不发全局通知.否则只发全局通知
 */
@property (nonatomic,weak) id <SGNetworkStatusDelegate> delegate;

/**
 *  是否支持IPv4,默认全部支持
 */
@property (nonatomic,assign) BOOL supportIPv4;

/**
 *  是否支持IPv6
 */
@property (nonatomic,assign) BOOL supportIPv6;

/**
 *  有很小概率ping失败(实际没有断网),设定多少次ping失败认为是断网,默认2次
 */
@property (nonatomic,assign) NSUInteger failureTimes;

/**
 *  ping 的频率,默认1s
 */
@property (nonatomic,assign) NSTimeInterval interval;

/**
 *  默认www.baidu.com
 */
+ (instancetype)defultObsever;

/**
 *  自定义地址
 */
+ (instancetype)observerWithHost:(NSString *)host openURL:(NSString *) openURL;

/**
 *  开始监控
 */
- (void)startNotifier;

/**
 *  停止监控
 */
- (void)stopNotifier;
@end
