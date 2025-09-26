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

RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE(RTCAudioFrame) : NSObject

/** Number of channels in the buffer (1 = mono, 2 = stereo). */
@property(nonatomic, readonly) NSUInteger channels;

/** Number of frames per channel contained in this buffer. */
@property(nonatomic, readonly) NSUInteger frames;

/** Sample rate in Hz. */
@property(nonatomic, readonly) int sampleRate;

/** Capture timestamp for the first sample, in nanoseconds. */
@property(nonatomic, readonly) int64_t timestampNs;

/** Returns a read-only view of the interleaved PCM payload (16-bit). */
@property(nonatomic, readonly) NSData *pcmData;

/** Convenience helper returning the PCM payload cast to int16_t. */
- (const int16_t *)int16Data;

/**
 * Initializes an audio frame by copying the provided interleaved PCM payload.
 *
 * @param pcm Interleaved 16-bit PCM samples. The data is copied.
 * @param frames Number of frames per channel contained in `pcm`.
 * @param sampleRate Sample rate in Hz.
 * @param channels Number of interleaved channels (1 = mono, 2 = stereo).
 * @param timestampNs Capture timestamp for the first sample (nanoseconds).
 */
- (instancetype)initWithPCM:(const int16_t *)pcm
                      frames:(NSUInteger)frames
                  sampleRate:(int)sampleRate
                    channels:(NSUInteger)channels
                 timestampNs:(int64_t)timestampNs NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
