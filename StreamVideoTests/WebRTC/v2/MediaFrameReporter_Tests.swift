//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Dispatch
import ObjectiveC
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MediaFrameReporter_Tests: XCTestCase, @unchecked Sendable {
    func test_add_rendererInvokedOutsideCooperativePool() async throws {
        let subject = MediaFrameReporter(clientEventReporter: NoOpClientEventReporter())
        let factory = PeerConnectionFactory.mock()
        let track = factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
        let selector = #selector(RTCVideoTrack.add(_:))
        let method = try XCTUnwrap(class_getInstanceMethod(RTCVideoTrack.self, selector))
        let originalImplementation = method_getImplementation(method)
        let original = unsafeBitCast(
            originalImplementation,
            to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self
        )
        let queues = Atomic(wrappedValue: [String]())
        let replacement: @convention(block) (RTCVideoTrack, AnyObject) -> Void = { currentTrack, renderer in
            if currentTrack === track {
                queues.mutate { $0.append(String(cString: __dispatch_queue_get_label(nil))) }
            }
            original(currentTrack, selector, renderer)
        }
        let replacementImplementation = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementImplementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(replacementImplementation)
        }

        await subject.add(track, type: .video)
        await subject.removeAllTracks()

        XCTAssertFalse(queues.wrappedValue.isEmpty)
        XCTAssertFalse(queues.wrappedValue.contains { $0.contains("cooperative") }, "\(queues.wrappedValue)")
        XCTAssertFalse(queues.wrappedValue.contains("com.apple.main-thread"))
    }
}
