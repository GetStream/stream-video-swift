//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ObjectiveC
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class TrackEvent_Tests: XCTestCase, @unchecked Sendable {
    func test_description_doesNotReadTrackEnabledState() throws {
        let factory = PeerConnectionFactory.mock()
        let track = factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
        let selector = #selector(getter: RTCMediaStreamTrack.isEnabled)
        let method = try XCTUnwrap(class_getInstanceMethod(RTCMediaStreamTrack.self, selector))
        let originalImplementation = method_getImplementation(method)
        let reads = Atomic(wrappedValue: 0)
        let replacement: @convention(block) (RTCMediaStreamTrack) -> Bool = { _ in
            reads.mutate { $0 += 1 }
            return true
        }
        let replacementImplementation = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementImplementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(replacementImplementation)
        }

        _ = String(describing: TrackEvent.added(id: "track", trackType: .video, track: track))
        _ = String(describing: TrackEvent.removed(id: "track", trackType: .video, track: track))

        XCTAssertEqual(reads.wrappedValue, 0)
    }
}
