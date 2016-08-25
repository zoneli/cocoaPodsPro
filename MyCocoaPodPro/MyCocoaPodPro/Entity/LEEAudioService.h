//
//  LEEAudioService.h
//  MyCocoaPodPro
//
//  Created by lyz1 on 16/8/25.
//  Copyright © 2016年 lyz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <AVFoundation/AVFoundation.h>
@interface LEEAudioService : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>{

}
- (void)createAudioService:(NSString *)cachePath;
- (RACSignal *)startAudioRecord;
- (void)stopAudioRecord;
@end
