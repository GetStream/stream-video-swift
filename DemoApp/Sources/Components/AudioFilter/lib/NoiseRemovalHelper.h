//
//  ViewController.h
//  denoiser_demo
//
//  Created by 邱威 on 2022/9/6.
//

#import <UIKit/UIKit.h>

@interface NoiseRemovalHelper : NSObject

@property (nonatomic, assign) int sampleRate;

- (float *)denoiseWithBuffer:(float *)inputBuffer frameSize:(int)frameSize;
- (void)createWith:(int)sampleRate;
- (void)destroy;

@end

