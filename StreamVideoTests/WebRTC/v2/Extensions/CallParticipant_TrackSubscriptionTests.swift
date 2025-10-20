//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallParticipant_TrackSubscriptionTests: XCTestCase, @unchecked Sendable {

    func test_trackSubscriptionDetails_givenParticipantHasVideoAndNotDisabled_whenVideoAllowed_thenAddsVideoTrackDetails() {
        // Given
        let participant = CallParticipant.dummy(
            id: "session1",
            hasVideo: true,
            hasAudio: false,
            isScreenSharing: false,
            trackSize: CGSize(width: 1280, height: 720)
        )
        let incomingSettings = IncomingVideoQualitySettings.manual(
            group: .custom(sessionIds: ["session1"]),
            targetSize: CGSize(width: 1920, height: 1080)
        )

        // When
        let result = participant.trackSubscriptionDetails(incomingVideoQualitySettings: incomingSettings)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.trackType, .video)
        XCTAssertEqual(result.first?.dimension.width, 1920)
        XCTAssertEqual(result.first?.dimension.height, 1080)
    }

    func test_trackSubscriptionDetails_givenParticipantHasAudio_whenAudioIsPresent_thenAddsAudioTrackDetails() {
        // Given
        let participant = CallParticipant.dummy(
            id: "session1",
            hasVideo: false,
            hasAudio: true,
            isScreenSharing: false
        )
        let incomingSettings = IncomingVideoQualitySettings.none

        // When
        let result = participant.trackSubscriptionDetails(incomingVideoQualitySettings: incomingSettings)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.trackType, .audio)
    }

    func test_trackSubscriptionDetails_givenParticipantIsScreensharing_whenSharingScreen_thenAddsScreenShareTrackDetails() {
        // Given
        let participant = CallParticipant.dummy(
            id: "session1",
            hasVideo: false,
            hasAudio: false,
            isScreenSharing: true
        )
        let incomingSettings = IncomingVideoQualitySettings.none

        // When
        let result = participant.trackSubscriptionDetails(incomingVideoQualitySettings: incomingSettings)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.trackType, .screenShare)
        XCTAssertEqual(result.last?.trackType, .screenShareAudio)
    }

    func test_trackSubscriptionDetails_givenParticipantHasVideoAndVideoIsDisabled_whenVideoDisabled_thenDoesNotAddVideoTrackDetails(
    ) {
        // Given
        let participant = CallParticipant.dummy(
            id: "session1",
            hasVideo: true,
            hasAudio: false,
            isScreenSharing: false,
            trackSize: CGSize(width: 1280, height: 720)
        )
        let incomingSettings = IncomingVideoQualitySettings.disabled(group: .custom(sessionIds: ["session1"]))

        // When
        let result = participant.trackSubscriptionDetails(incomingVideoQualitySettings: incomingSettings)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_trackSubscriptionDetails_givenVideoEnabledAndSessionNotInGroup_whenSessionNotIncluded_thenUsesTrackSize() {
        // Given
        let participant = CallParticipant.dummy(
            id: "session1",
            hasVideo: true,
            hasAudio: false,
            isScreenSharing: false,
            trackSize: CGSize(width: 1280, height: 720)
        )
        let incomingSettings = IncomingVideoQualitySettings.manual(
            group: .custom(
                sessionIds: ["session2"]
            ),
            targetSize: CGSize(width: 1920, height: 1080)
        )

        // When
        let result = participant.trackSubscriptionDetails(incomingVideoQualitySettings: incomingSettings)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.trackType, .video)
        XCTAssertEqual(result.first?.dimension.width, 1280)
        XCTAssertEqual(result.first?.dimension.height, 720)
    }
}
