//
//  SecondViewController.h
//  MyCocoaPodPro
//
//  Created by lyz1 on 16/5/21.
//  Copyright © 2016年 lyz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
@interface SecondViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
@property IBOutlet UIButton *btn;
@property IBOutlet UIButton *endBtn;

@end

