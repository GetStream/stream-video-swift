//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallParticipants_Tests: XCTestCase, @unchecked Sendable {

    func test_callParticipant_audioLevels() {
        // Given
        var callParticipant = CallParticipant(
            id: "123",
            userId: "123",
            roles: [],
            name: "Test",
            profileImageURL: nil,
            trackLookupPrefix: nil,
            hasVideo: false,
            hasAudio: true,
            isScreenSharing: false,
            showTrack: false,
            isDominantSpeaker: false,
            sessionId: "123",
            connectionQuality: .excellent,
            joinedAt: Date(),
            audioLevel: 0,
            audioLevels: [],
            pin: nil,
            pausedTracks: []
        )
        
        // When
        callParticipant = callParticipant.withUpdated(isSpeaking: true, audioLevel: 0.4)
        callParticipant = callParticipant.withUpdated(isSpeaking: true, audioLevel: 0.6)
        
        // Then
        XCTAssert(callParticipant.audioLevels == [0.4, 0.6])
    }
    
    func test_callParticipant_mapping() {
        // Given
        var sfuParticipant = Stream_Video_Sfu_Models_Participant()
        sfuParticipant.sessionID = "123-session"
        sfuParticipant.userID = "123"
        sfuParticipant.audioLevel = 0.1
        sfuParticipant.trackLookupPrefix = "123-track"
        sfuParticipant.connectionQuality = .excellent
        
        // When
        let participant = sfuParticipant.toCallParticipant()
        
        // Then
        XCTAssert(participant.sessionId == "123-session")
        XCTAssert(participant.userId == "123")
        XCTAssert(participant.audioLevel == 0.1)
        XCTAssert(participant.trackLookupPrefix == "123-track")
        XCTAssert(participant.connectionQuality == .excellent)
    }

    // MARK: - shouldDisplayTrack

    func test_shouldDisplayTrack_hasVideoFalse_returnsFalse() {
        let subject = CallParticipant.dummy(
            hasVideo: false,
            showTrack: false,
            track: nil
        )

        XCTAssertFalse(subject.shouldDisplayTrack)
    }

    func test_shouldDisplayTrack_hasVideoTrueShowTrackFalse_returnsFalse() {
        let subject = CallParticipant.dummy(
            hasVideo: true,
            showTrack: false,
            track: nil
        )

        XCTAssertFalse(subject.shouldDisplayTrack)
    }

    func test_shouldDisplayTrack_hasVideoTrueShowTrackTrueTrackNil_returnsFalse() {
        let subject = CallParticipant.dummy(
            hasVideo: true,
            showTrack: true,
            track: nil
        )

        XCTAssertFalse(subject.shouldDisplayTrack)
    }

    func test_shouldDisplayTrack_hasVideoTrueShowTrackTrueTrackNotNil_returnsTrue() {
        let subject = CallParticipant.dummy(
            hasVideo: true,
            showTrack: true,
            track: PeerConnectionFactory.mock().mockVideoTrack(forScreenShare: false)
        )

        XCTAssertTrue(subject.shouldDisplayTrack)
    }

    func test_shouldDisplayTrack_hasVideoTrueShowTrackTrueTrackNotNilPausedTracksContainsVideo_returnsFalse() {
        let subject = CallParticipant.dummy(
            hasVideo: true,
            showTrack: true,
            track: PeerConnectionFactory.mock().mockVideoTrack(forScreenShare: false),
            pausedTracks: [.video]
        )

        XCTAssertFalse(subject.shouldDisplayTrack)
    }

    func test_shouldDisplayTrack_hasVideoTrueShowTrackTrueTrackNotNilPausedTracksDoesNotContainVideo_returnstrue() {
        let subject = CallParticipant.dummy(
            hasVideo: true,
            showTrack: true,
            track: PeerConnectionFactory.mock().mockVideoTrack(forScreenShare: false),
            pausedTracks: []
        )

        XCTAssertTrue(subject.shouldDisplayTrack)
    }

    // MARK: - Equatable

    func test_isEqual_participantWithDifferentPausedTracksAreNotEqual() {
        let participantA = CallParticipant.dummy(pausedTracks: [.video])
        let participantB = participantA.withPausedTrack(.audio)

        XCTAssertNotEqual(participantA, participantB)
    }

    // MARK: - withUpdated

    func test_withUpdated_preservesSource() {
        let subject = CallParticipant.dummy(source: .rtmp)

        XCTAssertEqual(subject.withUpdated(showTrack: true).source, .rtmp)
        XCTAssertEqual(subject.withUpdated(audio: true).source, .rtmp)
        XCTAssertEqual(subject.withUpdated(trackSize: .init(width: 1, height: 1)).source, .rtmp)
    }

    func test_withUpdated_preservesReactions() {
        let reaction = CallReaction.dummy(type: ":raise-hand:")
        let subject = CallParticipant.dummy(reactions: [reaction])

        XCTAssertEqual(subject.withUpdated(showTrack: true).reactions, [reaction])
        XCTAssertEqual(subject.withUpdated(audio: true).reactions, [reaction])
        XCTAssertEqual(subject.withUpdated(video: true).reactions, [reaction])
    }

    func test_withUpdated_reactions_replacesReactions() {
        let reaction = CallReaction.dummy(type: ":like:")
        let subject = CallParticipant.dummy(reactions: [.dummy(type: ":raise-hand:")])

        XCTAssertEqual(subject.withUpdated(reactions: [reaction]).reactions, [reaction])
    }

    func test_isEqual_participantsWithDifferentReactionsAreNotEqual() {
        let subject = CallParticipant.dummy(id: "1", reactions: [])

        XCTAssertNotEqual(subject, subject.withUpdated(reactions: [.dummy()]))
    }
}
