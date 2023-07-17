//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class Sorting_Tests: XCTestCase {
    
    private let mockResponseBuilder = MockResponseBuilder()

    func testSortByScreensharingAndUserId() {
        // Given
        let participant1 = makeCallParticipant(id: "1")
        let participant2 = makeCallParticipant(id: "2", isScreenSharing: true)
        let participant3 = makeCallParticipant(id: "3")
        let participants = [participant1, participant2, participant3]
        
        // When
        let sortedParticipants = participants.sorted(using: [screensharing, userId])
        
        // Then
        XCTAssertEqual(sortedParticipants, [participant2, participant3, participant1])
    }
    
    func testSortByDominantSpeakerAndIsSpeaking() {
        // Given
        let participant1 = makeCallParticipant(id: "1", isSpeaking: true, isDominantSpeaker: true)
        let participant2 = makeCallParticipant(id: "2")
        let participant3 = makeCallParticipant(id: "3", isSpeaking: true)
        let participants = [participant1, participant2, participant3]
        
        // When
        let sortedParticipants = participants.sorted(using: [dominantSpeaker, isSpeaking, userId])
        
        // Then
        XCTAssertEqual(sortedParticipants, [participant1, participant3, participant2])
    }
    
    func testMultipleCriteriaSorting() {
        // Given
        let p1 = makeCallParticipant(
            id: "123",
            name: "Alice",
            roles: ["speaker"],
            hasVideo: true,
            hasAudio: true,
            isScreenSharing: false,
            isSpeaking: true,
            isDominantSpeaker: false
        )
        let p2 = makeCallParticipant(
            id: "234",
            name: "Bob",
            roles: ["listener"],
            hasVideo: false,
            hasAudio: true,
            isScreenSharing: true,
            isSpeaking: false,
            isDominantSpeaker: false
        )
        let p3 = makeCallParticipant(
            id: "345",
            name: "Charlie",
            roles: ["listener"],
            hasVideo: false,
            hasAudio: false,
            isScreenSharing: false,
            isSpeaking: false,
            isDominantSpeaker: true
        )
        let participants = [p1, p2, p3]

        // When
        // Sort by user id in ascending order
        let sorted1 = participants.sorted(using: [userId], order: .ascending)
        // Then
        XCTAssertEqual(sorted1.map(\.userId), ["123", "234", "345"])

        // When
        // Sort by screensharing (false first) and then by user id in descending order
        let sorted2 = participants.sorted(using: [screensharing, userId], order: .descending)
        // Then
        XCTAssertEqual(sorted2.map(\.userId), ["234", "345", "123"])

        // When
        // Sort by publishing video (true first) and then by publishing audio (true first) in ascending order
        let sorted3 = participants.sorted(using: [publishingVideo, publishingAudio], order: .ascending)
        // Then
        XCTAssertEqual(sorted3.map(\.userId), ["345", "234", "123"])

        // When
        // Sort by is speaking (true first), dominant speaker (true first), and then user id in descending order
        let sorted4 = participants.sorted(using: [isSpeaking, dominantSpeaker, userId], order: .descending)
        // Then
        XCTAssertEqual(sorted4.map(\.userId), ["123", "345", "234"])
    }
    
    func testSortingRoles() {
        // Given
        let participant1 = makeCallParticipant(id: "1", roles: ["user"])
        let participant2 = makeCallParticipant(id: "2", roles: ["speaker", "host"])
        let participant3 = makeCallParticipant(id: "3", roles: ["admin", "host"])
        let participant4 = makeCallParticipant(id: "4", roles: ["speaker"])
        let participant5 = makeCallParticipant(id: "5")
        let participants = [participant1, participant2, participant3, participant4, participant5]
        
        // When
        let sorted = participants.sorted(using: [roles, userId])
        
        // Then
        XCTAssertEqual(sorted.map(\.id), ["3", "2", "4", "5", "1"])
    }
    
    private func makeCallParticipant(
        id: String,
        name: String = "",
        roles: [String] = [],
        hasVideo: Bool = false,
        hasAudio: Bool = false,
        isScreenSharing: Bool = false,
        isSpeaking: Bool = false,
        isDominantSpeaker: Bool = false
    ) -> CallParticipant {
        mockResponseBuilder.makeCallParticipant(
            id: id,
            name: name,
            roles: roles,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreenSharing,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker
        )
    }
    
}
