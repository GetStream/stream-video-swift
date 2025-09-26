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

#if !defined(__OBJC__)
#error "RTCAudioCapturer.h requires Objective-C/Objective-C++ compilation"
#endif

@class RTC_OBJC_TYPE(RTCAudioCapturer);
@class RTC_OBJC_TYPE(RTCAudioFrame);

RTC_OBJC_EXPORT
@protocol RTC_OBJC_TYPE(RTCAudioCapturerDelegate)<NSObject>
- (void)capturer:(RTC_OBJC_TYPE(RTCAudioCapturer) *)capturer
    didCaptureAudioFrame:(RTC_OBJC_TYPE(RTCAudioFrame) *)frame;
@end

RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE (RTCAudioCapturer) : NSObject

@property(nonatomic, weak) id<RTC_OBJC_TYPE(RTCAudioCapturerDelegate)> delegate;

- (instancetype)initWithDelegate:
    (id<RTC_OBJC_TYPE(RTCAudioCapturerDelegate)>)delegate;

@end
