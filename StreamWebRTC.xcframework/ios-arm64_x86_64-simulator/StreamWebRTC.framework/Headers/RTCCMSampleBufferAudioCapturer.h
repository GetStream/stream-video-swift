/*
 * Copyright 2025 The WebRTC project authors. All Rights Reserved.
 *
 * Use of this source code is governed by a BSD-style license
 * that can be found in the LICENSE file in the root of the source
 * tree. An additional intellectual property rights grant can be found
 * in the file PATENTS. All contributing project authors may
 * be found in the AUTHORS file in the root of the source tree.
 */

#import <CoreMedia/CoreMedia.h>

#import <StreamWebRTC/RTCAudioCapturer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Captures interleaved 16-bit PCM from CMSampleBuffer sources (e.g. ReplayKit)
 * and forwards 10 ms audio frames to its delegate.
 */
RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE(RTCCMSampleBufferAudioCapturer) : RTC_OBJC_TYPE(RTCAudioCapturer)

/** Indicates whether captured buffers should be forwarded to the delegate. */
@property(nonatomic, readonly, getter=isRunning) BOOL running;

/** Starts forwarding sample buffers to the delegate. */
- (void)start;

/** Stops forwarding sample buffers to the delegate and clears internal state. */
- (void)stop;

/**
 * Consumes an audio CMSampleBuffer. The caller owns `sampleBuffer` and is
 * responsible for keeping it valid for the duration of the call.
 */
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
