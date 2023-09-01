//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class PiPTrackSelectionUtils_Tests: StreamVideoTestCase {
    
    @Injected(\.utils) var utils
    
    let trackSelectionUtils = PiPTrackSelectionUtils()
    
    override func setUp() {
        super.setUp()
        utils.videoRendererFactory.clearViews()
    }
    
    func test_trackSelection_otherUser() {
        // Given
        let currentUserId = "current"
        let otherUserId = "test"
        let size = CGSize(width: 100, height: 100)
        let otherUserView = utils.videoRendererFactory.view(for: otherUserId, size: size)
        _ = utils.videoRendererFactory.view(for: otherUserId, size: size)

        let callParticipant = makeCallParticipant(id: otherUserId)
        let current = makeCallParticipant(id: currentUserId)
        let callParticipants = [otherUserId: callParticipant, currentUserId: current]
        
        // When
        let renderer = trackSelectionUtils.pipVideoRenderer(
            from: callParticipants,
            currentSessionId: currentUserId
        )
        
        // Then
        XCTAssertNotNil(renderer)
        XCTAssertEqual(renderer?.trackId, otherUserView.trackId)
    }

    func test_trackSelection_screensharingOtherUser() {
        // Given
        let currentUserId = "current"
        let otherUserId = "test"
        let screenshareId = "test-screenshare"
        let size = CGSize(width: 100, height: 100)
        let otherUserView = utils.videoRendererFactory.view(for: screenshareId, size: size)
        _ = utils.videoRendererFactory.view(for: otherUserId, size: size)

        let callParticipant = makeCallParticipant(id: otherUserId, isScreenSharing: true)
        let current = makeCallParticipant(id: currentUserId)
        let callParticipants = [otherUserId: callParticipant, currentUserId: current]
        
        // When
        let renderer = trackSelectionUtils.pipVideoRenderer(
            from: callParticipants,
            currentSessionId: currentUserId
        )
        
        // Then
        XCTAssertNotNil(renderer)
        XCTAssertEqual(renderer?.trackId, otherUserView.trackId)
    }
    
    func test_trackSelection_currentUser() {
        // Given
        let currentUserId = "current"
        let size = CGSize(width: 100, height: 100)
        let currentView = utils.videoRendererFactory.view(for: currentUserId, size: size)
        let current = makeCallParticipant(id: currentUserId)
        let callParticipants = [currentUserId: current]
        
        // When
        let renderer = trackSelectionUtils.pipVideoRenderer(
            from: callParticipants,
            currentSessionId: currentUserId
        )
        
        // Then
        XCTAssertNotNil(renderer)
        XCTAssertEqual(renderer?.trackId, currentView.trackId)
    }
    
    func test_trackSelection_empty() {
        // Given
        let currentUserId = "current"
        let current = makeCallParticipant(id: currentUserId)
        let callParticipants = [currentUserId: current]
        
        // When
        let renderer = trackSelectionUtils.pipVideoRenderer(
            from: callParticipants,
            currentSessionId: currentUserId
        )
        
        // Then
        XCTAssertNil(renderer)
    }
    
    //MARK: - private
    
    private func makeCallParticipant(
        id: String,
        name: String = "",
        roles: [String] = [],
        hasVideo: Bool = false,
        hasAudio: Bool = false,
        isScreenSharing: Bool = false,
        isSpeaking: Bool = false,
        isDominantSpeaker: Bool = false,
        pin: PinInfo? = nil
    ) -> CallParticipant {
        let participant = CallParticipant(
            id: id,
            userId: id,
            roles: roles,
            name: name,
            profileImageURL: nil,
            trackLookupPrefix: nil,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreenSharing,
            showTrack: true,
            track: nil,
            trackSize: .zero,
            screenshareTrack: nil,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: id,
            connectionQuality: .unknown,
            joinedAt: Date(),
            audioLevel: 0,
            audioLevels: [],
            pin: pin
        )
        return participant
    }

}
