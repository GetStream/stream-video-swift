//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCVideoTrack_CloneTests: XCTestCase, @unchecked Sendable {

    func test_clone_preservesEnabledState() {
        let factory = PeerConnectionFactory.mock()
        let originalTrack = factory.mockVideoTrack(forScreenShare: false)
        originalTrack.isEnabled = true

        let clonedTrack = originalTrack.clone(from: factory)

        XCTAssertEqual(clonedTrack.isEnabled, originalTrack.isEnabled)
    }

    func test_clone_createsNewTrack() {
        let factory = PeerConnectionFactory.mock()
        let originalTrack = factory.mockVideoTrack(forScreenShare: false)

        let clonedTrack = originalTrack.clone(from: factory)

        XCTAssertNotEqual(clonedTrack.trackId, originalTrack.trackId)
        XCTAssertTrue(clonedTrack.source === originalTrack.source)
    }
}
