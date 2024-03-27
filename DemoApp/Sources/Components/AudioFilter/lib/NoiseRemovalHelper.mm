//
//  ViewController.m
//  denoiser_demo
//
//  Created by 邱威 on 2022/9/6.
//

#import "NoiseRemovalHelper.h"
#include "denoiser.h"

@interface NoiseRemovalHelper ()

@end

@implementation NoiseRemovalHelper
{
    void* denoiser_;
}

- (instancetype)init {
    [self createWith: 48000];
    return [super init];
}

- (float *)denoiseWithBuffer:(float *)inputBuffer frameSize:(int)frameSize {
    // Process each frame with the denoiser
    float *in_buffer = inputBuffer;
    float *out_buffer = (float *)malloc(frameSize*sizeof(float));
    
    NSProcess(denoiser_, in_buffer, frameSize, out_buffer);

    free(out_buffer);
    
    return out_buffer;
}

- (void)createWith:(int)sampleRate {
    _sampleRate = sampleRate;
    denoiser_ = NSCreate(_sampleRate);
}

- (void)destroy {
    NSDestroy(denoiser_);
}

@end
