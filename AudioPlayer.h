//
//  AudioPlayer.h
//  14音频播放
//
//  Created by wyzc03 on 16/10/27.
//  Copyright © 2016年 wyzc03. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "Masonry/Masonry.h"

typedef enum : NSInteger {
    simpleLoop = 0,//单个循环
    repeatAll = 1,//整体循环
    none = 2,//不循环默认是不循环
} loopModel;
//
@protocol AudioPlayerDelegate <NSObject>
@optional
//把视频播放的当前时间 和 总时间传递给外界
- (void)timeScheduleWithCurrentTime:(float)currentTime andTotalTime:(float)totalTime;
@end

@interface AudioPlayer : NSObject
@property (nonatomic,assign) id<AudioPlayerDelegate> delegate;
//用于存放多个视频路径
@property (nonatomic,strong) NSArray * videoArray;
//用于播放视频的视图
@property (nonatomic,strong) UIView * movieView;
//初始化方式
+ (instancetype)sharedAudioPlayer;
//播放本地文件
- (void)playFileWithPath:(NSString *)path;
//暂停
- (void)pause;
//开始
- (void)start;
//调整音量
- (void)setPlayerVolume:(float)voice;
//跳转到某个时间
- (void)seekToDestinationTime:(double)time;
//播放下一个
- (void)playNextVideo;
//播放上一个
- (void)playLastOne;
//循环模式选择
- (void)chooseLoopModel:(loopModel)loopModel;
@end






