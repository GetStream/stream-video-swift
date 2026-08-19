//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class Stream_Video_Sfu_Models_CallGrants_OwnCapability_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - applied(to:)

    func test_applied_allGrantsAllowed_addsMissingCapabilities() {
        let subject = makeGrants(audio: true, video: true, screenshare: true)

        XCTAssertEqual(
            subject.applied(to: []),
            [.sendAudio, .sendVideo, .screenshare]
        )
    }

    func test_applied_someGrantsRevoked_removesRevokedCapabilities() {
        let subject = makeGrants(audio: true, video: false, screenshare: false)

        XCTAssertEqual(
            subject.applied(to: [.sendAudio, .sendVideo, .screenshare]),
            [.sendAudio]
        )
    }

    func test_applied_unrelatedCapabilities_remainUntouched() {
        let subject = makeGrants(audio: false, video: false, screenshare: false)

        XCTAssertEqual(
            subject.applied(to: [.endCall, .sendAudio, .muteUsers]),
            [.endCall, .muteUsers]
        )
    }

    func test_applied_sameGrantsTwice_producesSameCapabilities() {
        let subject = makeGrants(audio: true, video: false, screenshare: true)

        let once = subject.applied(to: [.sendVideo, .endCall])

        XCTAssertEqual(subject.applied(to: once), once)
    }

    // MARK: - Private helpers

    private func makeGrants(
        audio: Bool,
        video: Bool,
        screenshare: Bool
    ) -> Stream_Video_Sfu_Models_CallGrants {
        var result = Stream_Video_Sfu_Models_CallGrants()
        result.canPublishAudio = audio
        result.canPublishVideo = video
        result.canScreenshare = screenshare
        return result
    }
}
