//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ObjectiveC
@testable import StreamVideo
import StreamWebRTC
import XCTest

func captureFrameRenderer(
    track: RTCMediaStreamTrack,
    type: TrackType,
    reporter: MediaFrameReporter
) async throws -> MediaFrameTrackRenderer {
    let trackClass: AnyClass = type == .audio ? RTCAudioTrack.self : RTCVideoTrack.self
    let selector = type == .audio ? #selector(RTCAudioTrack.add(_:)) : #selector(RTCVideoTrack.add(_:))
    let method = try XCTUnwrap(class_getInstanceMethod(trackClass, selector))
    let originalIMP = method_getImplementation(method)
    let original = unsafeBitCast(
        originalIMP,
        to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self
    )
    let captured = Atomic<MediaFrameTrackRenderer?>(wrappedValue: nil)
    let intercept: @convention(block) (AnyObject, AnyObject) -> Void = { currentTrack, renderer in
        if currentTrack === track {
            captured.wrappedValue = renderer as? MediaFrameTrackRenderer
        }
        original(currentTrack, selector, renderer)
    }
    let interceptIMP = imp_implementationWithBlock(intercept)
    method_setImplementation(method, interceptIMP)
    defer {
        method_setImplementation(method, originalIMP)
        imp_removeBlock(interceptIMP)
    }
    await reporter.add(track, type: type)
    return try XCTUnwrap(captured.wrappedValue)
}
