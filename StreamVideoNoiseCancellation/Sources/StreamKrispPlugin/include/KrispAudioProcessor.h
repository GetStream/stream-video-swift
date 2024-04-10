//
//  KrispAudioProcessor.h
//  KrispAudioProcessor
//
//  Created by Arthur Hayrapetyan on 26.01.23.
//  Copyright © 2023 Krisp Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTCAudioBuffer;

@interface KrispAudioProcessor : NSObject

- (instancetype)initWithParams:(NSString*)weightFile size:(unsigned int)size isVad:(BOOL)isVad;

- (void)initializeSessionWithSampleRate:(size_t)sampleRateHz
                               channels:(size_t)channels;

- (void)process:(RTCAudioBuffer *)audioBuffer;

- (void)destroy;

- (BOOL)isValid;

@end

