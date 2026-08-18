//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallGrants_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - init(protobuf)

    func test_init_fromProtobuf_mapsAllFields() {
        var source = Stream_Video_Sfu_Models_CallGrants()
        source.canPublishAudio = true
        source.canPublishVideo = false
        source.canScreenshare = true

        let subject = CallGrants(source)

        XCTAssertTrue(subject.canPublishAudio)
        XCTAssertFalse(subject.canPublishVideo)
        XCTAssertTrue(subject.canScreenshare)
    }

    // MARK: - applied(to:)

    func test_applied_allGranted_addsMissingCapabilities() {
        let subject = CallGrants(
            canPublishAudio: true,
            canPublishVideo: true,
            canScreenshare: true
        )

        let result = subject.applied(to: [])

        XCTAssertEqual(Set(result), [.sendAudio, .sendVideo, .screenshare])
    }

    func test_applied_partiallyGranted_removesRevokedCapabilities() {
        let subject = CallGrants(
            canPublishAudio: true,
            canPublishVideo: false,
            canScreenshare: false
        )

        let result = subject.applied(to: [.sendAudio, .sendVideo, .screenshare])

        XCTAssertEqual(result, [.sendAudio])
    }

    func test_applied_leavesUnrelatedCapabilitiesUntouched() {
        let subject = CallGrants(
            canPublishAudio: false,
            canPublishVideo: false,
            canScreenshare: false
        )

        let result = subject.applied(to: [.endCall, .sendAudio, .muteUsers])

        XCTAssertEqual(result, [.endCall, .muteUsers])
    }

    func test_applied_twice_isIdempotent() {
        let subject = CallGrants(
            canPublishAudio: true,
            canPublishVideo: false,
            canScreenshare: true
        )

        let once = subject.applied(to: [.sendVideo, .endCall])
        let twice = subject.applied(to: once)

        XCTAssertEqual(once, twice)
    }
}
