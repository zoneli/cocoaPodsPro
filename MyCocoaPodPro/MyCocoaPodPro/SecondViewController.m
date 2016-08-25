//
//  SecondViewController.m
//  MyCocoaPodPro
//
//  Created by lyz1 on 16/5/21.
//  Copyright © 2016年 lyz. All rights reserved.
//

#import "SecondViewController.h"
#define CAPTURE_FRAMES_PER_SECOND       20
#define SAMPLE_RATE                     44100
#define VideoWidth                      480
#define VideoHeight                     640

@interface SecondViewController ()
{
    AVCaptureSession *captureSession;
    dispatch_queue_t _audioQueue;
    AVCaptureConnection* _audioConnection;
    AVCaptureConnection* _videoConnection;
    NSMutableData *_data;
    UIImageView *tempView;
    AVAssetWriter   *_writer;
    AVAssetWriterInput *_videoInput;
    AVAssetWriterInput *_audioInput;
}
@property (nonatomic,copy)NSString *path;
@property (nonatomic,assign)BOOL isCapturing;
@property (nonatomic,assign)BOOL isPaused;
@property (nonatomic,assign)BOOL isCreateASSet;
@property (nonatomic,strong)AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic,strong)AVCaptureVideoDataOutput *videoOutput;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _data = [[NSMutableData alloc] init];
    captureSession = [[AVCaptureSession alloc] init];
    
    tempView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 260, self.view.frame.size.width, 200)];
    tempView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:tempView];
    
    [_btn addTarget:self action:@selector(btnToucheUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_endBtn addTarget:self action:@selector(endBtnToucheUpInside:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)btnToucheUpInside:(id)sender {
    [self startCamera];
    [self createAVCaptrue];
}
-(void)endBtnToucheUpInside:(id)sender {
    [self stopCarmera];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.title = @"分类";
}
- (void)createAVCaptrue {
    UIView *videoPreviewView=[[UIView alloc] initWithFrame:CGRectMake(0, 60,self.view.frame.size.width, 200)];
    [self.view addSubview:videoPreviewView];
    
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: captureSession];
    previewLayer.frame = videoPreviewView.bounds; //视频显示到的UIView
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoPreviewView.layer addSublayer: previewLayer];

}
#pragma mark
#pragma mark - 设置音频 capture
- (void) setupAudioCapture {
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@", error.description);
    }
    if ([captureSession canAddInput:audioInput]) {
        [captureSession addInput:audioInput];
    }    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    AVCaptureAudioDataOutput* audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([captureSession canAddOutput:audioOutput]) {
        [captureSession addOutput:audioOutput];
    }
    _audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

#pragma mark
#pragma mark - 设置视频 capture
- (void) setupVideoCaprure {
    
    NSError *deviceError;
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    outputDevice.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey: (id)kCVPixelBufferPixelFormatTypeKey];

    NSError *error;
    [cameraDevice lockForConfiguration:&error];
    if (error == nil) {
        
        NSLog(@"cameraDevice.activeFormat.videoSupportedFrameRateRanges IS %@",[cameraDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0]);
        
        if (cameraDevice.activeFormat.videoSupportedFrameRateRanges){
            
            [cameraDevice setActiveVideoMinFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
            [cameraDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
        }
    }else{
        // handle error2
    }
    [cameraDevice unlockForConfiguration];
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // initialize capture session
    if ([captureSession canAddInput:inputDevice]) {
        [captureSession addInput:inputDevice];
    }
    if ([captureSession canAddOutput:outputDevice]) {
        [captureSession addOutput:outputDevice];
    }
    
    [captureSession beginConfiguration];
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset1280x720]];
    _videoConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
    //Set landscape (if required)
    if ([_videoConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
        [_videoConnection setVideoOrientation:orientation];
    }
    
    
}

#pragma mark
#pragma mark - sampleBuffer 数据
//-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
//    
//    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//    double dPTS = (double)(pts.value) / pts.timescale;
////    NSLog(@"%fdpts",dPTS);
//    if (connection == _videoConnection) {
//        
//        
//        
//    } else if (connection == _audioConnection) {
//        CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
//        size_t length = CMBlockBufferGetDataLength(blockBufferRef);
//        Byte buffer[length];
//        CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
//        NSData *bufferdata = [NSData dataWithBytes:buffer length:length];
//        [_data appendData:bufferdata];
//    }
//    
//}

#pragma mark
#pragma mark - 视频数据回调
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"Video data (%lu): %@", (unsigned long)data.length, data.description);
    
}

#pragma mark
#pragma mark - 录制
- (void) startCamera
{
    [self setupAudioCapture];
    [self setupVideoCaprure];
    [captureSession commitConfiguration];
    [captureSession startRunning];
    [self createAVAssetWriter];
}

- (void) stopCarmera {

    [captureSession stopRunning];
    [_writer finishWritingWithCompletionHandler:^{
        NSLog(@"finish");
    }];
    
    // 获取程序Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSMutableString * path = [[NSMutableString alloc]initWithString:documentsDirectory];
    [path appendString:@"/AACFile"];
    [_data writeToFile:path atomically:YES];
    
}
//buffer to image
- (void)bufferTransToImage:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    UIImage *image;
    image = [UIImage imageWithCGImage:newImage];
    CGImageRelease(newImage);
}
#pragma mark 视频录制
- (void)createAVAssetWriter {
    if (self.isCreateASSet) {
        return;
    }
    self.isCreateASSet = YES;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSMutableString * path = [[NSMutableString alloc]initWithString:documentsDirectory];
    [path appendString:@"/video.mp4"];
//    delete item
    if (path) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSURL* url = [NSURL fileURLWithPath:path];
    _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
    //使其更适合在网络上播放
    _writer.shouldOptimizeForNetworkUse = YES;
    //初始化视频输出
    NSInteger cy = 640;
    NSInteger cx = 200;
    [self initVideoInputHeight:cy width:cx];
    Float64 rate = 44100.0;
    int ch = 1;
    //确保采集到rate和ch
    if (rate != 0 && ch != 0) {
        //初始化音频输出
        [self initAudioInputChannels:ch samples:rate];
    }
    
}
//初始化视频输入
- (void)initVideoInputHeight:(NSInteger)cy width:(NSInteger)cx {
    //录制视频的一些配置，分辨率，编码方式等等
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              AVVideoCodecH264, AVVideoCodecKey,
                              [NSNumber numberWithInteger: cx], AVVideoWidthKey,
                              [NSNumber numberWithInteger: cy], AVVideoHeightKey,
                              nil];
    //初始化视频写入类
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _videoInput.expectsMediaDataInRealTime = YES;
    //将视频输入源加入
    [_writer addInput:_videoInput];
}
//初始化音频输入
- (void)initAudioInputChannels:(int)ch samples:(Float64)rate {
    //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [ NSNumber numberWithInt: ch], AVNumberOfChannelsKey,
                              [ NSNumber numberWithFloat: rate], AVSampleRateKey,
                              [ NSNumber numberWithInt: 128000], AVEncoderBitRateKey,
                              nil];
    //初始化音频写入类
    _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _audioInput.expectsMediaDataInRealTime = YES;
    //将音频输入源加入
    [_writer addInput:_audioInput];
    
}
#pragma mark - 写入数据
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    BOOL isVideo = YES;
    @synchronized(self) {
        if (connection != _videoConnection) {
            isVideo = NO;
        }
        [self encodeFrame:sampleBuffer isVideo:isVideo];
//        CFRelease(sampleBuffer);
    }

}

//设置音频格式
//- (void)setAudioFormat:(CMFormatDescriptionRef)fmt {
//    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
//    _samplerate = asbd->mSampleRate;
//    _channels = asbd->mChannelsPerFrame;
//    
//}

//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

//通过这个方法写入数据
- (void)encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL)isVideo {
    //数据是否准备写入
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        if (_writer.status == AVAssetWriterStatusUnknown && isVideo) {
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //开始写入
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        //写入失败
        if (_writer.status == AVAssetWriterStatusFailed) {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
        }
        if (isVideo) {
            if (_videoInput.readyForMoreMediaData == YES) {
                [_videoInput appendSampleBuffer:sampleBuffer];
            }
        }else {
            if (_audioInput.readyForMoreMediaData) {
                [_audioInput appendSampleBuffer:sampleBuffer];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
