//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioTrack_CloneTests: XCTestCase, @unchecked Sendable {

    func test_clone_preservesEnabledState() {
        let factory = PeerConnectionFactory.mock()
        let originalTrack = factory.mockAudioTrack()
        originalTrack.isEnabled = true

        let clonedTrack = originalTrack.clone(from: factory)

        XCTAssertEqual(clonedTrack.isEnabled, originalTrack.isEnabled)
    }

    func test_clone_createsNewTrack() {
        let factory = PeerConnectionFactory.mock()
        let originalTrack = factory.mockAudioTrack()

        let clonedTrack = originalTrack.clone(from: factory)

        XCTAssertNotEqual(clonedTrack.trackId, originalTrack.trackId)
        XCTAssertTrue(clonedTrack.source === originalTrack.source)
    }
}
