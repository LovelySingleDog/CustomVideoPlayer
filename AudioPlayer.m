//
//  AudioPlayer.m
//  14音频播放
//
//  Created by wyzc03 on 16/10/27.
//  Copyright © 2016年 wyzc03. All rights reserved.
//

#import "AudioPlayer.h"
@interface AudioPlayer ()
@property (nonatomic,strong) AVPlayer * player;
@property (nonatomic,strong) AVPlayerItem * item;
@property (nonatomic,strong) NSLock * lock;//线程同步锁
//用于视频播放的layer
@property (nonatomic,strong) AVPlayerLayer * layer;
//记录循环的模式
@property (nonatomic,assign) loopModel loopMo;

@property (nonatomic,strong) id timeObserver;
@end


@implementation AudioPlayer
#pragma mark 同时重写setter 和 getter 要声明,因为同时重写setter和getter系统就不会生成 _属性了
//@synthesize movieView = _movieView;


//单例设计模式
static AudioPlayer * audioPlayer = nil;//第一步静态实例 并初始化

+ (instancetype)sharedAudioPlayer{      //第二步 实例构造 检查静态实例是否为nil
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (audioPlayer == nil) {
            audioPlayer = [[AudioPlayer alloc]init];
        }
    });
    return audioPlayer;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{//第三步 重写alloc方法
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (audioPlayer == nil) {
            audioPlayer = [super allocWithZone:zone];
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        }
    });
    return audioPlayer;
}
//第四步 重写一些其他的东西
- (instancetype)init{
    @synchronized(self) {
        if (self = [super init]) {
            //这里写默认的一些东西
            //初始化锁
            self.lock = [[NSLock alloc]init];
            //初始化AVPlayer
            [self initAVPlayerItemAndAVPlayer];
            //初始化循环方式
            self.loopMo = none;
            
            
            [self addPeriodicTimeObserver];
            //添加通知中心接收 播放完毕 的通知
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        }
        return audioPlayer;
    }
}

- (id)copy{
    return audioPlayer;
}
- (id)mutableCopy{
    return audioPlayer;
}

//======================================================================
#pragma mark 播放完毕走的方法(通知中心走的方法)
- (void)playEnd{
    if (self.loopMo == simpleLoop) {
        [self playFileWithPath:self.videoArray[number]];
    }else if (self.loopMo == repeatAll){
        [self playNextVideo];
    }else{
    }
}
#pragma mark 添加固定时间周期观察者
- (void)addPeriodicTimeObserver{
    __weak typeof (self) temp =self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //判断是否有代理
        if (temp.delegate != nil && [temp.delegate respondsToSelector:@selector(timeScheduleWithCurrentTime:andTotalTime:)]) {
            float current = CMTimeGetSeconds(time);
            float total = CMTimeGetSeconds(temp.item.duration);
            //current 和 total的时间都有实际意义才传出去
            if (!([[NSString stringWithFormat:@"%f",total] isEqualToString:@"nan"] || [[NSString stringWithFormat:@"%f",current] isEqualToString:@"nan"])) {
                //将值传出去
                [temp.delegate timeScheduleWithCurrentTime:current andTotalTime:total];
            }
        }
        
    }];
    
}
#pragma mark 重写getter方法
- (NSArray *)videoArray
{
    [_lock lock];
    if (_videoArray == nil) {
        _videoArray = [NSArray array];
    }
    [_lock unlock];
    return _videoArray;
}
#pragma mark 初始化AVPlayerItem以及AVPlayer
- (void)initAVPlayerItemAndAVPlayer{
    //number的作用 一个工程中只创建一次palyer
    [_lock lock];//线程安全
    static int number = 0;
    number ++;
    if (number == 1) {
        self.item = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:@""]];
        //self.item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@""]];
        self.player = [AVPlayer playerWithPlayerItem:self.item];
    }else{
        number = 2;//重置number的数字 以免 number ++ 一直加到超出int类型的范围
    }
    [_lock unlock];
}


#pragma mark 播放本地文件
- (void)playFileWithPath:(NSString *)path{
    [_lock lock];
    static NSString * path1;
    //数据地址不相同才执行新的播放事件
    if ([path isEqualToString:path1] && self.loopMo != simpleLoop) {
    }else{
        NSURL * url = [NSURL fileURLWithPath:path];
        //NSLog(@"%@",path);
        self.item = [AVPlayerItem playerItemWithURL:url];
        [self.player replaceCurrentItemWithPlayerItem:self.item];
        //执行播放
        [self.player play];
        //NSLog(@"path不相等");
    }
    path1 = path;
    [_lock unlock];
}

//懒加载方式 只让视频出现在最后调用setMovieView的视图上
#pragma mark  重写layer的getter方法
- (AVPlayerLayer *)layer
{
    [_lock lock];
    if (_layer == nil) {
        //初始化layer//初始化layer的时候player一点是先创建的
        _layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    }
    [_lock unlock];
    return _layer;
}
#pragma mark 重写movieView setter方法
- (void)setMovieView:(UIView *)movieView
{
    if (_movieView != movieView) {
        //在这里初始化layer时 只要用到该方法一次,那个视图上就会有一个视频//初始化layer的时候player一点是先创建的
        //self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        //设置layer尺寸
        self.layer.frame = movieView.bounds;
        //将layer添加到movieView
        [movieView.layer addSublayer:self.layer];
    }
}

//暂停
- (void)pause{
    [self.player pause];
}
//开始
- (void)start{
    [self.player play];
}
//跳转到某个时间
- (void)seekToDestinationTime:(double)time{
    CMTime tim = CMTimeMake(time, 1);
    [self.player seekToTime:tim];
}
//播放下一个
static NSInteger number = 0;//用于记录播放的是第几个文件
- (void)playNextVideo{
    NSArray * videoArr = self.videoArray;
    [_lock lock];
    ++ number;
    if (number == videoArr.count) {
        number = 0;
    }
    [_lock unlock];
    [self playFileWithPath:videoArr[number]];
}
//播放上一个
- (void)playLastOne{
    [_lock lock];
    -- number;
    if (number <= -1) {
        number = _videoArray.count - 1;
    }
    [_lock unlock];
    [self playFileWithPath:self.videoArray[number]];
}
//循环模式选择
- (void)chooseLoopModel:(loopModel)loopModel{
    self.loopMo = loopModel;
}

//销毁观察者和通知中心释放内存
- (void)dealloc{
    //被销毁时移除通知中心
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    //NSLog(@"通知中心被销毁");
    //周期观察者被销毁
    [self.player removeTimeObserver:self.timeObserver];
}
//调整音量
- (void)setPlayerVolume:(float)voice{
    [self.player setVolume:voice];
}

@end



















