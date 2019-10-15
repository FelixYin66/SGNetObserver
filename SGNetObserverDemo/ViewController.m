//
//  ViewController.m
//  SGNetObserverDemo
//
//  Created by apple on 16/9/19.
//  Copyright © 2016年 iOSSinger. All rights reserved.
//

#import "ViewController.h"
#import "SGNetObserver.h"

@interface ViewController ()
@property (nonatomic,strong) SGNetObserver *observer;

@property(nonatomic,strong) UIButton *startBtn;
@property(nonatomic,strong) UIButton *stopBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     self.observer = [SGNetObserver observerWithHost:@"test.thefront.com.cn"];
    [self viewLayout];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:SGReachabilityChangedNotification object:nil];
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SGReachabilityChangedNotification object:nil];
}
- (void)networkStatusChanged:(NSNotification *)notify{
    NSLog(@"notify-------%@",notify.userInfo);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//    MARK: View Layout

- (void) viewLayout{
    [self.view addSubview:self.startBtn];
    [self.view addSubview:self.stopBtn];
    [self.startBtn sizeToFit];
    [self.stopBtn sizeToFit];
    self.startBtn.frame = CGRectMake(30, 100, self.startBtn.frame.size.width, self.startBtn.frame.size.height);
    self.stopBtn.frame = CGRectMake(self.startBtn.frame.size.width + self.startBtn.frame.origin.x + 30, 100, self.stopBtn.frame.size.width, self.stopBtn.frame.size.height);
}

//    MARK: View Event

- (void) startBtnClick:(UIButton *) btn{
    [self.observer startNotifier];
}

- (void) stopBtnClick:(UIButton *) btn{
    [self.observer stopNotifier];
}

//    MARK: Lazy Loading

- (UIButton *)startBtn{
    if (!_startBtn) {
        _startBtn = [[UIButton alloc] init];
        [_startBtn setTitle:@"开始测试" forState:UIControlStateNormal];
        [_startBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        _startBtn.backgroundColor = [UIColor blueColor];
        [_startBtn addTarget:self action:@selector(startBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

- (UIButton *)stopBtn{
    if (!_stopBtn) {
        _stopBtn = [[UIButton alloc] init];
        [_stopBtn setTitle:@"停止测试" forState:UIControlStateNormal];
        [_stopBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        _stopBtn.backgroundColor = [UIColor blueColor];
        [_stopBtn addTarget:self action:@selector(stopBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopBtn;
}

@end
