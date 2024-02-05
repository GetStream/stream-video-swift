//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallParticipants_Tests: XCTestCase {

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
            pin: nil
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
}
