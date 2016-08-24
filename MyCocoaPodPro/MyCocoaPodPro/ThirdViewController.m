//
//  ThirdViewController.m
//  MyCocoaPodPro
//
//  Created by lyz1 on 16/5/21.
//  Copyright © 2016年 lyz. All rights reserved.
//

#import "ThirdViewController.h"

@interface ThirdViewController ()
{
    NSArray* _videoUrls;
    NSMutableArray* _playerItems;
    AVQueuePlayer* _queuePlayer;

}
@property(nonatomic,copy)NSString *netUrl;
@property(nonatomic,copy)NSString *mnetUrl;
@property(nonatomic,copy)NSString *localUrl;
@end

@implementation ThirdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _netUrl = @"http://g3.letv.com/vod/v1/MTg5LzIzLzc2L2xldHYtZ3VnLzE3L3Zlcl8wMF8yMi0xMDU0MTg4Mzc4LWF2Yy0yNTc2MjUtYWFjLTMyNzQwLTE0OTIwLTU2MzIyNi0yNzUxYTMxNDE4YjEwNWFjYTlhYzM4YjUwYmVkYjA3Ny0xNDY3ODc3MjE2NTU3Lm1wNA==?platid=100&splatid=10000&gugtype=1&mmsid=59936443&type=m_liuchang_mp4&playid=0&termid=2&pay=0&hwtype=iphone&ostype=macos&m3v=3";
    _mnetUrl= @"http://g3.letv.com/vod/v1/MTQ3LzcvOS9sZXR2LWd1Zy8xNy92ZXJfMDBfMjItMzMyMDMxNzUtYXZjLTE2MTc3MC1hYWMtMzIxODktMTUwMDAtMzgxNjc0LWEyZjgzZDkzZDBjOWMwODk2NTk3NTgzYTE2MmNlOGUxLTE0MzY4NzQwNjkyNzEubXA0?platid=100&splatid=10000&gugtype=1&mmsid=33091820&type=m_liuchang_mp4&tss=ios";
    
    _localUrl= [[NSBundle mainBundle]pathForResource:@"1" ofType:@"mp4"];
//    [self createAVQueuePlayer];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.title = @"附近";    
}
- (void)createAVQueuePlayer {
    
    _playerItems = [[NSMutableArray alloc]init];
    AVURLAsset* itemAsset1 = [[AVURLAsset alloc] initWithURL: [NSURL URLWithString:_netUrl] options: nil];
    AVPlayerItem* playItem1 = [[AVPlayerItem alloc] initWithAsset: itemAsset1];
    
    AVURLAsset* itemAsset3 = [[AVURLAsset alloc] initWithURL: [NSURL URLWithString:_mnetUrl] options: nil];
    AVPlayerItem* playItem3 = [[AVPlayerItem alloc] initWithAsset: itemAsset3];
    
    AVURLAsset* itemAsset2 = [[AVURLAsset alloc] initWithURL: [NSURL fileURLWithPath:_localUrl] options: nil];
    AVPlayerItem* playItem2 = [[AVPlayerItem alloc] initWithAsset: itemAsset2];
    [playItem2 addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (playerItemDidPlayToEndTime:) name: AVPlayerItemDidPlayToEndTimeNotification object: playItem1];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (playerItemDidPlayToEndTime:) name: AVPlayerItemDidPlayToEndTimeNotification object: playItem2];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (playerItemDidPlayToEndTime:) name: AVPlayerItemDidPlayToEndTimeNotification object: playItem3];
    
    if (playItem1 != nil &&playItem2 != nil) {
        [_playerItems addObject: playItem2];
        [_playerItems addObject: playItem1];
        [_playerItems addObject: playItem3];
    }
    _queuePlayer = [[AVQueuePlayer alloc] initWithItems: _playerItems];
    _queuePlayer.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_queuePlayer];
    playerLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, 480);
    [self.view.layer addSublayer:playerLayer];
    [_queuePlayer play];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - kvo avPlayer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *tempplayerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([tempplayerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"-----AVPlayerStatusReadyToPlay-");
        } else if ([tempplayerItem status] == AVPlayerStatusFailed) {
            NSLog(@"-----AVPlayerStatusFailed-");
        }else if(AVPlayerStatusUnknown == [tempplayerItem status]){
            NSLog(@"-----AVPlayerStatusUnknown-");
            
        }
    }
}
- (void) playerItemDidPlayToEndTime: (NSNotification*) notification
{
    [_queuePlayer advanceToNextItem];

}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
