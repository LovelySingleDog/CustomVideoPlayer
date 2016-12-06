//
//  AudioPlayerViewController.h
//  自定义音频视频播放
//
//  Created by wyzc03 on 16/10/31.
//  Copyright © 2016年 wyzc03. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioPlayerViewController : UIViewController
//输入存放视频文件夹的本地地址
@property (nonatomic,copy) NSString * filePath;
+ (instancetype)sharedAudioPlayerViewController;
@end
