//
//  SecondViewController.m
//  MyCocoaPodPro
//
//  Created by lyz1 on 16/5/21.
//  Copyright © 2016年 lyz. All rights reserved.
//

#import "SecondViewController.h"
#import "LEEAudioService.h"
@interface SecondViewController ()
{
    NSMutableData *_data;
}
@property(nonatomic,strong)LEEAudioService *audioService;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _data = [[NSMutableData alloc] init];
    _audioService = [[LEEAudioService alloc]init];
    [_audioService createAudioService:nil];
    [_btn addTarget:self action:@selector(btnToucheUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_endBtn addTarget:self action:@selector(endBtnToucheUpInside:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)btnToucheUpInside:(id)sender {
    RACSignal *singal = [_audioService startAudioRecord];
    singal = [singal doNext:^(id x) {
        NSLog(@"donext");
    }];
    [singal subscribeNext:^(id x) {
        AVCaptureSession *session = x;
        [self createAVCaptrueWithSession:session];
        NSLog(@"subscribeNext");
    }];
    
}
-(void)endBtnToucheUpInside:(id)sender {
    [_audioService stopAudioRecord];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.title = @"分类";
}
- (void)createAVCaptrueWithSession:(AVCaptureSession *)captureSession {
    UIView *videoPreviewView=[[UIView alloc] initWithFrame:CGRectMake(0, 60,self.view.frame.size.width, 200)];
    [self.view addSubview:videoPreviewView];
    
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: captureSession];
    previewLayer.frame = videoPreviewView.bounds; //视频显示到的UIView
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoPreviewView.layer addSublayer: previewLayer];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
