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
}
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
- (void) setupVideoCaprure
{
    
    NSError *deviceError;
    
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //    cameraDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    //    cameraDevice.position = AVCaptureDevicePositionBack;
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    

    // make output device
    
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    outputDevice.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey: (id)kCVPixelBufferPixelFormatTypeKey];
//    NSNumber* val = [NSNumber
//                     numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
//    NSDictionary* videoSettings =
//    [NSDictionary dictionaryWithObject:val forKey:key];
    
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
//    outputDevice.videoSettings = videoSettings;
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // initialize capture session
    if ([captureSession canAddInput:inputDevice]) {
        [captureSession addInput:inputDevice];
    }
    if ([captureSession canAddOutput:outputDevice]) {
        [captureSession addOutput:outputDevice];
    }
    
    // begin configuration for the AVCaptureSession
    [captureSession beginConfiguration];
    
    // picture resolution
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset640x480]];
    _videoConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
    
    //Set landscape (if required)
    if ([_videoConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;        //<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [_videoConnection setVideoOrientation:orientation];
    }
    
    
}

#pragma mark
#pragma mark - sampleBuffer 数据
-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
    
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    double dPTS = (double)(pts.value) / pts.timescale;
    
    if (connection == _videoConnection) {
        [self bufferTransToImage:sampleBuffer];
    } else if (connection == _audioConnection) {
        CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t length = CMBlockBufferGetDataLength(blockBufferRef);
        Byte buffer[length];
        CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
        NSData *bufferdata = [NSData dataWithBytes:buffer length:length];
        [_data appendData:bufferdata];
    }
    
}
- (void)bufferTransToImage:(CMSampleBufferRef)sampleBuffer {
//    if (tempView) {
//        return;
//    }
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
        
        // Get information of the image
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
//        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        CGContextRelease(newContext);
        
        CGColorSpaceRelease(colorSpace);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        /* CVBufferRelease(imageBuffer); */  // do not call this!
        
        
        UIImage *image;
        image = [UIImage imageWithCGImage:newImage];
        CGImageRelease(newImage);
//    if (tempView==nil) {
//        tempView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 400, self.view.frame.size.width, 100)];
//        tempView.backgroundColor = [UIColor clearColor];
        tempView.image = image;
//        [self.view addSubview:tempView];
//    }
}

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
}

- (void) stopCarmera {

    [captureSession stopRunning];
    //close(fd);
    // 获取程序Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSMutableString * path = [[NSMutableString alloc]initWithString:documentsDirectory];
    [path appendString:@"/AACFile"];
    [_data writeToFile:path atomically:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
