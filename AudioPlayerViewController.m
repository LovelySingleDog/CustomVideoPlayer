//
//  AudioPlayerViewController.m
//  自定义音频视频播放
//
//  Created by wyzc03 on 16/10/31.
//  Copyright © 2016年 wyzc03. All rights reserved.
//

#import "AudioPlayerViewController.h"
#import "AudioPlayer.h"
#import <AVKit/AVKit.h>
@interface AudioPlayerViewController ()<AudioPlayerDelegate>
//自定义的AudioPlayer
@property (nonatomic,weak) AudioPlayer * player;
//播放下一个按钮
@property (nonatomic,strong) UIButton * playNextButton;
//播放上一个按钮
@property (nonatomic,strong) UIButton * playLastButton;
//进度条
@property (nonatomic,strong) UISlider * timeSlider;
//为了线程安全
@property (nonatomic,strong) NSLock * lock;
//用来存储视频路径的数组
@property (nonatomic,strong) NSMutableArray * pathArray;
//存储视频名字的数组
@property (nonatomic,strong) NSMutableArray * nameArray;
//显示视频名字的label
@property (nonatomic,strong) UILabel * showNameLabel;
@property (nonatomic,assign) NSInteger nameArrIndex;//记录显示名字的下标
//播放按钮
@property (nonatomic,strong) UIButton * playButton;
//循环模式button
@property (nonatomic,strong) UIButton * loopModelButton;
//退出按钮
@property (nonatomic,strong) UIButton * quitButton;
//方底端控件的视图
@property (nonatomic,strong) UIView * bottomView;
//用来判断控件显示的状态 0 显示控件 1 不显示控件
@property (nonatomic,assign) NSInteger Height;
//音量条
@property (nonatomic,strong) UISlider * volumeSlider;

@end

@implementation AudioPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addData];
}
#pragma mark 单例设计
//静态实例化
static AudioPlayerViewController * audioPlayerVC = nil;

+ (instancetype)sharedAudioPlayerViewController{
    return [[self alloc] init];
}
//重写方法
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (audioPlayerVC == nil) {
            audioPlayerVC = [super allocWithZone:zone];
        }
    });
    return audioPlayerVC;
}
- (instancetype)init{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioPlayerVC = [super init];
    });
    return audioPlayerVC;
}
//copy
- (id)copy{
    return audioPlayerVC;
}
- (id)mutableCopy{
    return audioPlayerVC;
}

#pragma mark 添加数据
- (void)addData{
    //UIDevice
    //初始化
    _player = [AudioPlayer sharedAudioPlayer];
    self.pathArray = [NSMutableArray array];
    self.lock = [[NSLock alloc]init];
    self.Height = 0;
    self.view.backgroundColor = [UIColor blackColor];
    self.nameArray = [NSMutableArray array];
    self.nameArrIndex = 0;
    //正则表达式 查找是否是视频文件
    NSString * suffix = @"^.*\.[mp4]$";
    //文件路径
    NSFileManager * manager = [NSFileManager defaultManager];
    //拿到文件夹下的所有文件的名字
    NSArray * pathArr = [manager subpathsAtPath:self.filePath];
    
    NSPredicate * pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",suffix];
    
    //遍历数组找到可以支持的视频路径添加到数组中
    for (NSString * fileName in pathArr) {
        //判断是佛是视频文件
        BOOL result = [pre evaluateWithObject:fileName];
        if (result) {
            NSArray * tempArr = [fileName componentsSeparatedByString:@"."];
            [self.nameArray addObject:[tempArr firstObject]];
            //将视频路径组装到数组中
            NSString * subPath = [self.filePath stringByAppendingPathComponent:fileName];
            [self.pathArray addObject:subPath];
        }
    }
    
    //添加数据
    self.player.videoArray = self.pathArray;
    //选择循环模式
    [self.player chooseLoopModel:none];
    //设置代理
    self.player.delegate = self;
    static int times = 0;
    times ++;
    if (times == 1) {
        self.playButton.selected = NO;
        //播放第一个视频
        [self.player playFileWithPath:[self.pathArray firstObject]];
        //初始化showNameLabel的文字
        self.showNameLabel.text = [self.nameArray firstObject];
        //初始化音量
        [self.player setPlayerVolume:0.5];
        //旋转音量调到竖直
        [self rotainVolumeSlider];
    }else{
        times = 2;
    }
    
}
#pragma mark 初始化组件//懒加载
#pragma mark 退出按钮
- (UIButton *)quitButton
{
    if (_quitButton == nil) {
        _quitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_quitButton setTitle:@"退出" forState:UIControlStateNormal];
        [_quitButton addTarget:self action:@selector(quiteButtonAction:) forControlEvents:UIControlEventTouchDown];
    }
    return _quitButton;
}
#pragma mark 退出按钮走的方法
- (void)quiteButtonAction:(UIButton *)sender{
    self.playButton.selected = YES;
    [self.player pause];
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}
#pragma mark 循环按钮
- (UIButton *)loopModelButton
{
    if (_loopModelButton == nil) {
        _loopModelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loopModelButton addTarget:self action:@selector(loopModelButtonAction:) forControlEvents:UIControlEventTouchDown];
        [_loopModelButton setTitle:@"不循环" forState:UIControlStateNormal];
    }
    return _loopModelButton;
}
#pragma mark 循环按钮走的方法
- (void)loopModelButtonAction:(UIButton *)sender{
    [_lock lock];
    NSArray * array = @[@"单个循环",@"整体循环",@"不循环"];
    static NSInteger index = -1;
    index ++;
    if (index == 3) {
        index = 0;
    }
    [self.loopModelButton setTitle:array[index] forState:UIControlStateNormal];
    for (int i = 0; i < 3; i ++) {
        if ([self.loopModelButton.titleLabel.text isEqualToString:array[i]]) {
            [self.player chooseLoopModel:i];
        }
    }
    [_lock unlock];
}
#pragma mark 播放按钮
- (UIButton *)playButton
{
    if (_playButton == nil) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setTitle:@"播放" forState:UIControlStateSelected];
        [_playButton setTitle:@"暂停" forState:UIControlStateNormal];
        _playButton.selected = YES;
        [_playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchDown];
    }
    return _playButton;
}
#pragma mark 播放按钮方法
- (void)playButtonAction:(UIButton *)sender{
    if (sender.selected == YES ) {
        sender.selected = NO;
        [self.player start];
    }else{
        sender.selected = YES;
        [self.player pause];
    }
}
- (UIButton *)playNextButton{
    if (_playNextButton == nil) {
        //播放下一个
        self.playNextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playNextButton addTarget:self action:@selector(playNext:) forControlEvents:UIControlEventTouchDown];
        [self.playNextButton setTitle:@"下一个" forState:UIControlStateNormal];
    }
    return _playNextButton;
}
#pragma mark 播放下一个的方法
- (void)playNext:(UIButton *)sender{
    [self.player playNextVideo];
    self.playButton.selected = NO;
    self.nameArrIndex ++;
    if (self.nameArrIndex == self.nameArray.count) {
        self.nameArrIndex = 0;
    }
    self.showNameLabel.text = self.nameArray[self.nameArrIndex];
    
}
#pragma mark 播放上一个
- (UIButton *)playLastButton
{
    if (_playLastButton == nil) {
        //播放上一个
        self.playLastButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playLastButton addTarget:self action:@selector(playLast:) forControlEvents:UIControlEventTouchDown];
        [self.playLastButton setTitle:@"上一个" forState:UIControlStateNormal];
    }
    return _playLastButton;
}
#pragma mark 播放上一个方法
- (void)playLast:(UIButton *)sender{
    [self.player playLastOne];
    self.playButton.selected = NO;
    self.nameArrIndex --;
    if (self.nameArrIndex <= -1) {
        self.nameArrIndex = self.nameArray.count - 1;
    }
    self.showNameLabel.text = self.nameArray[self.nameArrIndex];
}

#pragma mark 进度条timerSlider
- (UISlider *)timeSlider{
    if (_timeSlider == nil) {
        _timeSlider = [[UISlider alloc]init];
        _timeSlider.minimumValue = 0;
        [_timeSlider addTarget:self action:@selector(timeSliderAction:) forControlEvents:UIControlEventValueChanged];
        [_timeSlider addTarget:self action:@selector(touchUpInside) forControlEvents:UIControlEventTouchUpInside];
    }
    return _timeSlider;
}
#pragma mark timerSlider滑动时的方法
- (void)timeSliderAction:(UISlider *)sender{
    //让播放器停止播放再跳转到某个时间 就可以解决滑块抖动的问题
    [self.player pause];
    [self.player seekToDestinationTime:self.timeSlider.value];
}
#pragma mark timerSlider滑动结束时走的方法
- (void)touchUpInside{
    //滑动结束后开始播放
    [self.player start];
    self.playButton.selected = NO;
}
#pragma mark 音量调
- (UISlider *)volumeSlider
{
    if (_volumeSlider == nil) {
        _volumeSlider = [[UISlider alloc]init];
        _volumeSlider.minimumValue = 0;
        _volumeSlider.maximumValue = 1;
        _volumeSlider.value = 0.5;
        [_volumeSlider addTarget:self action:@selector(volumeSliderAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _volumeSlider;
}
#pragma mark 音量条走的方法
- (void)volumeSliderAction:(UISlider *)sender{
    [self.player setPlayerVolume:sender.value];
}
#pragma mark 旋转音量调
- (void)rotainVolumeSlider{
    self.volumeSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
}
#pragma mark 底端加载控件视图
- (UIView *)bottomView
{
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc]init];
    }
    return _bottomView;
}
#pragma mark showNameLabel
- (UILabel *)showNameLabel{
    if (_showNameLabel == nil) {
        _showNameLabel = [[UILabel alloc]init];
        _showNameLabel.numberOfLines = 0;
        _showNameLabel.textAlignment = NSTextAlignmentCenter;
        _showNameLabel.textColor = [UIColor whiteColor];
    }
    return _showNameLabel;
}
#pragma mark 设置约束
- (void)makeConstraints{
    __weak typeof (self) temp = self;
    //bottomView
    [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.left.equalTo(temp.view);
        make.height.mas_equalTo(30);
        make.bottom.equalTo(temp.view.mas_bottom).offset(30 * temp.Height);
    }];
    //播放下一个
    [self.playNextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(60, 30));
        make.right.equalTo(temp.bottomView).offset(-20);
        make.bottom.equalTo(temp.bottomView);
    }];
    //播放上一个
    [self.playLastButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(60, 30));
        make.left.equalTo(temp.bottomView).offset(20);
        make.bottom.equalTo(temp.bottomView);
    }];
    //播放按钮
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(60, 30));
        make.centerX.equalTo(temp.bottomView);
        make.bottom.equalTo(temp.bottomView);
    }];
    //循环模式按钮
    [self.loopModelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.top.equalTo(temp.bottomView);
        make.right.equalTo(temp.playNextButton.mas_left);
        make.left.equalTo(temp.playButton.mas_right);
    }];
    //退出按钮
    [self.quitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(temp.playLastButton.mas_right);
        make.bottom.top.equalTo(temp.bottomView);
        make.right.equalTo(temp.playButton.mas_left);
    }];
    //进度条
    [self.timeSlider mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(temp.view).offset(10);
        make.right.equalTo(temp.view).offset(-10);
        make.bottom.equalTo(temp.view.mas_top).offset(-51 * temp.Height + 51);
    }];
    //显示名字的label
    [self.showNameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(20);
        make.right.equalTo(temp.view.mas_left).offset(- 25 * temp.Height + 25);
        make.top.equalTo(temp.timeSlider.mas_bottom).offset(5);
        make.bottom.equalTo(temp.playLastButton.mas_top).offset(-5);
    }];
    //音量条
    [self.volumeSlider mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(temp.view.mas_right).offset(-16 + 32 * temp.Height);
        make.centerY.equalTo(temp.view);
        make.width.mas_equalTo(200);
    }];
}

#pragma mark 将按钮添加到视图上
- (void)drawView{
    [self.view addSubview:self.bottomView];
    [self.bottomView addSubview:self.playNextButton];
    [self.bottomView addSubview:self.playLastButton];
    [self.bottomView addSubview:self.loopModelButton];
    [self.view addSubview:self.timeSlider];
    [self.bottomView addSubview:self.playButton];
    [self.bottomView addSubview:self.quitButton];
    [self.view addSubview:self.showNameLabel];
    [self.view addSubview:self.volumeSlider];
    //设置约束
    [self makeConstraints];
}
#pragma mark 视图已经布局子视图在这里给播放器的视图可以自动自适应屏幕
- (void)viewDidLayoutSubviews{
    //移除以前的控件 以免重复加载控件
    for (UIView * vie in self.view.subviews) {
        [vie removeFromSuperview];
    }
    //给player一个视图播放视频
    self.player.movieView = self.view;
    [self drawView];
}
#pragma mark 自定义代理
- (void)timeScheduleWithCurrentTime:(float)currentTime andTotalTime:(float)totalTime{
    //将视频具体时间以及当前时间传给timerSlider
    self.timeSlider.maximumValue = totalTime;
    self.timeSlider.value = currentTime;
}
#pragma mark 清除按钮
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    __weak typeof (self) temp = self;
    static int times = 0;
    times ++;
    if (times == 1) {
        self.Height = 1;//设置是否显示视频控件
        //更新约束
        [self.view setNeedsUpdateConstraints];
        [UIView animateWithDuration:0.3 animations:^{
            [temp.view layoutIfNeeded];
        }];
    }else{
        times = 0;
        self.Height = 0;//设置是否显示视频控件
        //更新约束
        [self.view setNeedsUpdateConstraints];
        [UIView animateWithDuration:0.3 animations:^{
            [temp.view layoutIfNeeded];
        }];
    }
}
#pragma mark 释放内存
- (void)dealloc{
    //NSLog(@"被释放");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidAppear:(BOOL)animated
{
    
}


@end

