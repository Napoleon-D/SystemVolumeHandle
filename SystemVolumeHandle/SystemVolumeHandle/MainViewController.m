//
//  ViewController.m
//  SystemVolumeHandle
//
//  Created by Tommy on 2018/8/27.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#define KRGBA(R,G,B,A) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:A]
#define K16Color(string) [UIColor colorWithHexString:string]

#import "MainViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface MainViewController ()

@property(nonatomic,strong)MPVolumeView *volumeView;
@property(nonatomic,assign)float lastSystemVolume;
@property(nonatomic,copy)NSString *volumeViewEventStatus;

@end

static NSString *VolumeViewEventViewDidAppear = @"VolumeViewEventViewDidAppear";
static NSString *VolumeViewEventViewWillDisappear = @"VolumeViewEventViewWillDisappear";

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"仿抖音系统音量处理";
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.volumeView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    /// 监听音量变化的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    /// 添加音量进度条
    if (![self.volumeView isDescendantOfView:self.view]) {
        [self.view addSubview:self.volumeView];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    /// 记录生命周期
    self.volumeViewEventStatus = VolumeViewEventViewDidAppear;
    /// 记录之前的音量
    self.lastSystemVolume = [AVAudioSession sharedInstance].outputVolume;
    /// 设置新的音量
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MPMusicPlayerController applicationMusicPlayer].volume = 0.1;
    });
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    /// 记录生命周期
    self.volumeViewEventStatus = VolumeViewEventViewWillDisappear;
    /// 恢复之前的系统音量
    [MPMusicPlayerController applicationMusicPlayer].volume = self.lastSystemVolume;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    /// 移除系统音量的监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    /// 移除音量条
    if ([self.volumeView isDescendantOfView:self.view]) {
        [self.volumeView removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (MPVolumeView *)volumeView{
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0,-1000, UIScreen.mainScreen.bounds.size.width, 2)];
        _volumeView.showsVolumeSlider = YES;
        _volumeView.showsRouteButton = NO;
        [_volumeView setVolumeThumbImage:[self imageWithColor:[UIColor clearColor] size:CGSizeMake(1, 1)] forState:UIControlStateNormal];
        [_volumeView setMaximumVolumeSliderImage:[self imageWithColor:KRGBA(255, 255, 255, 0.3) size:CGSizeMake(1, 1)] forState:UIControlStateNormal];
        [_volumeView setMinimumVolumeSliderImage:[self imageWithColor:[UIColor whiteColor] size:CGSizeMake(1, 1)] forState:UIControlStateNormal];
    }
    return _volumeView;
}


- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/// 检测系统音量变化的回调
- (void)volumeChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if ([self.volumeViewEventStatus isEqualToString:VolumeViewEventViewWillDisappear] || [self.volumeViewEventStatus isEqualToString:VolumeViewEventViewDidAppear]) {
            self.volumeViewEventStatus = @"";
            return ;
        };
        NSDictionary *userInfo = notification.userInfo;
        NSString *reasonStr = userInfo[@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"];
        if (![reasonStr isEqualToString:@"ExplicitVolumeChange"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.volumeView.frame.origin.y != 300)
                self.volumeView.frame = CGRectMake(0, 300, UIScreen.mainScreen.bounds.size.width, 2);
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenVolumeView) object:nil];
            [self performSelector:@selector(hiddenVolumeView) withObject:nil afterDelay:1];
        });
        
    });
    
}

- (void)hiddenVolumeView{
    if (self.volumeView.frame.origin.y != -1000) dispatch_async(dispatch_get_main_queue(), ^{
        self.volumeView.frame = CGRectMake(0, -1000, UIScreen.mainScreen.bounds.size.width, 2);
    });
}


@end
