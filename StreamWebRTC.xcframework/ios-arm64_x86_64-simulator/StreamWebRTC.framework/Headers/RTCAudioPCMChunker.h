/*
 *  Copyright 2025 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>

#import <StreamWebRTC/RTCMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class RTC_OBJC_TYPE(RTCAudioFrame);

/** Utility that buffers interleaved int16 PCM and emits 10 ms frames. */
RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE(RTCAudioPCMChunker) : NSObject

- (instancetype)initWithSampleRate:(int)sampleRate channels:(NSUInteger)channels;

/** Updates the chunker to a new format and clears pending samples. */
- (void)resetWithSampleRate:(int)sampleRate channels:(NSUInteger)channels;

/** Clears any buffered samples and timestamp state. */
- (void)flush;

/** Returns the number of pending frames awaiting emission. */
- (NSUInteger)pendingFrames;

@property(nonatomic, readonly) int sampleRate;
@property(nonatomic, readonly) NSUInteger channels;

/**
 * Consumes interleaved PCM, buffering until 10 ms of audio is available. For
 * each chunk, the handler is invoked on the caller's thread.
 *
 * @param samples Pointer to interleaved 16-bit PCM.
 * @param frames Number of frames per channel in `samples`.
 * @param sampleRate Sample rate of the input audio in Hz.
 * @param channels Number of interleaved channels in `samples`.
 * @param timestampNs Capture timestamp for the first sample (nanoseconds). Pass
 *        a value < 0 to allow the chunker to synthesize timestamps.
 * @param handler Invoked for every emitted audio frame.
 */
- (void)consumePCM:(const int16_t *)samples
            frames:(NSUInteger)frames
       sampleRate:(int)sampleRate
         channels:(NSUInteger)channels
      timestampNs:(int64_t)timestampNs
           handler:(void (^)(RTC_OBJC_TYPE(RTCAudioFrame) *frame))handler;

@end

NS_ASSUME_NONNULL_END
