//
//  ViewController.m
//  CocoaAsyncSocketDemo
//
//  Created by Gavin on 2020/4/8.
//  Copyright © 2020 GSNICE. All rights reserved.
//

#import "ViewController.h"

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface ViewController ()<GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UITextField *addressTF;        //  地址输入框
@property (weak, nonatomic) IBOutlet UITextField *portTF;           //  端口输入框
@property (weak, nonatomic) IBOutlet UIButton *connectControlBtn;   //  连接控制按钮
@property (weak, nonatomic) IBOutlet UITextField *messageTF;        //  发送信息输入框
@property (weak, nonatomic) IBOutlet UITextView *logTV;             //  Log 文本视图

- (IBAction)didClickToConnectServer:(UIButton *)sender;
- (IBAction)didClickToSendMessage:(UIButton *)sender;

//  客户端 socket
@property(nonatomic, strong) GCDAsyncSocket *clientSocket;
//  连接状态
@property(nonatomic, assign) BOOL connected;
//  心跳计时器
@property(nonatomic, strong) NSTimer *heartbeatTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self showMessageWithStr:@"链接成功" ClearText:YES];
    [self showMessageWithStr:[NSString stringWithFormat:@"服务器IP: %@-端口: %d", host,port] ClearText:NO];
    
    // 连接成功开启定时器
    [self addHeartbeatTimer];
    
    // 连接后,可读取服务端的数据
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    self.connected = YES;
    [self.connectControlBtn setSelected:YES];
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self showMessageWithStr:@"断开连接" ClearText:NO];
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
    self.connected = NO;
    [self.heartbeatTimer invalidate];
    [self.connectControlBtn setSelected:NO];
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self showMessageWithStr:[@"收到消息：" stringByAppendingString:text] ClearText:NO];
    // 读取到服务端数据值后,能再次读取
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - 显示Log信息
- (void)showMessageWithStr:(NSString *)string ClearText:(BOOL)clear {
    if (clear) {
        self.logTV.text = @"";
    }
    NSString *logStr = self.logTV.text;
    NSString *newString = [NSString stringWithFormat:@"%@\n",string];
    self.logTV.text = [newString stringByAppendingString:logStr];
}

#pragma mark - 添加心跳定时器
- (void)addHeartbeatTimer {
     // 长连接定时器，5秒发送一次心跳
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
     // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - 心跳连接
- (void)longConnectToSocket {
    NSString *longConnect = [NSString stringWithFormat:@"【心跳】%@",[UIDevice currentDevice].name];
    NSData  *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}

#pragma mark - 连接按钮执行操作
- (IBAction)didClickToConnectServer:(UIButton *)sender {
    if (!sender.isSelected) {
        //  初始化客户端 Socket
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        //  连接服务器
        NSError *error = nil;
        self.connected = [self.clientSocket connectToHost:self.addressTF.text onPort:[self.portTF.text integerValue] error:&error];
    }else{
        //  断开连接
        [self.clientSocket disconnect];
    }
}

#pragma mark - 发送按钮执行操作
- (IBAction)didClickToSendMessage:(UIButton *)sender {
    NSData *data = [self.messageTF.text dataUsingEncoding:NSUTF8StringEncoding];
    [self showMessageWithStr:[@"发送消息：" stringByAppendingString:self.messageTF.text] ClearText:NO];
    // withTimeout -1 : 无穷大,一直等
    // tag : 消息标记
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
    self.messageTF.text = @"";
}
@end
