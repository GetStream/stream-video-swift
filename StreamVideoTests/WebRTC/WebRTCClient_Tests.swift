//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCClient_Tests: StreamVideoTestCase {
    
    private let callCid = "default:123"
    private let sessionId = "123"
    private let userId = "martin"
    
    private lazy var participant: Stream_Video_Sfu_Models_Participant = {
        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = userId
        participant.sessionID = sessionId
        return participant
    }()
    
    private lazy var participantJoined: Stream_Video_Sfu_Event_ParticipantJoined = {
        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = callCid
        participantJoined.participant = participant
        return participantJoined
    }()

    func test_webRTCClient_participantJoinedAndLeft() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        
        // Then
        try await waitForCallEvent()
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.userId == userId)
        
        // When
        var participantLeft = Stream_Video_Sfu_Event_ParticipantLeft()
        participantLeft.callCid = callCid
        participantLeft.participant = participant
        webRTCClient.eventNotificationCenter.process(participantLeft)
        
        // Then
        try await waitForCallEvent()
        let left = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNil(left)
    }
    
    func test_webRTCClient_dominantSpeakerChanged() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var dominantSpeakerChanged = Stream_Video_Sfu_Event_DominantSpeakerChanged()
        dominantSpeakerChanged.sessionID = sessionId
        dominantSpeakerChanged.userID = userId
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(dominantSpeakerChanged)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isDominantSpeaker == true)
    }
    
    func test_webRTCClient_audioLevelsChanged() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var audioLevelsChanged = Stream_Video_Sfu_Event_AudioLevelChanged()
        var audioLevel = Stream_Video_Sfu_Event_AudioLevel()
        audioLevel.sessionID = sessionId
        audioLevel.userID = userId
        audioLevel.isSpeaking = true
        audioLevelsChanged.audioLevels = [audioLevel]
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(audioLevelsChanged)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isSpeaking == true)
    }
    
    func test_webRTCClient_connectionQualityChanged() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var connectionQualityChanged = Stream_Video_Sfu_Event_ConnectionQualityChanged()
        var update = Stream_Video_Sfu_Event_ConnectionQualityInfo()
        update.sessionID = sessionId
        update.userID = userId
        update.connectionQuality = .good
        connectionQualityChanged.connectionQualityUpdates = [update]
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(connectionQualityChanged)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.connectionQuality == .good)
    }
    
    func test_webRTCClient_joinResponse() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var joinResponse = Stream_Video_Sfu_Event_JoinResponse()
        joinResponse.callState.participants = [participant]
        
        // When
        webRTCClient.eventNotificationCenter.process(joinResponse)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.userId == userId)
    }
    
    func test_webRTCClient_audioTrackPublished() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var trackPublished = Stream_Video_Sfu_Event_TrackPublished()
        trackPublished.sessionID = sessionId
        trackPublished.userID = userId
        trackPublished.type = .audio
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(trackPublished)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasAudio == true)
    }
    
    func test_webRTCClient_videoTrackPublished() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var trackPublished = Stream_Video_Sfu_Event_TrackPublished()
        trackPublished.sessionID = sessionId
        trackPublished.userID = userId
        trackPublished.type = .video
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(trackPublished)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasVideo == true)
    }
    
    func test_webRTCClient_screenshareTrackPublished() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var trackPublished = Stream_Video_Sfu_Event_TrackPublished()
        trackPublished.sessionID = sessionId
        trackPublished.userID = userId
        trackPublished.type = .screenShare
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(trackPublished)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isScreensharing == true)
    }
    
    func test_webRTCClient_audioTrackUnpublished() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var trackUnpublished = Stream_Video_Sfu_Event_TrackUnpublished()
        trackUnpublished.sessionID = sessionId
        trackUnpublished.userID = userId
        trackUnpublished.type = .audio
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(trackUnpublished)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasAudio == false)
    }
    
    func test_webRTCClient_videoTrackUnpublished() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var trackUnpublished = Stream_Video_Sfu_Event_TrackUnpublished()
        trackUnpublished.sessionID = sessionId
        trackUnpublished.userID = userId
        trackUnpublished.type = .video
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(trackUnpublished)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasVideo == false)
    }
    
    func test_webRTCClient_screenshareTrackUnpublished() async throws {
        // Given
        let webRTCClient = makeWebRTCClient()
        var trackUnpublished = Stream_Video_Sfu_Event_TrackUnpublished()
        trackUnpublished.sessionID = sessionId
        trackUnpublished.userID = userId
        trackUnpublished.type = .screenShare
        
        // When
        webRTCClient.eventNotificationCenter.process(participantJoined)
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(trackUnpublished)
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isScreensharing == false)
    }
    
    // MARK: - private
    
    func makeWebRTCClient() -> WebRTCClient {
        let webRTCClient = WebRTCClient(
            user: StreamVideo.mockUser,
            apiKey: StreamVideo.apiKey,
            hostname: "test.com",
            token: StreamVideo.mockToken.rawValue,
            callCid: callCid,
            callCoordinatorController: CallCoordinatorController_Mock(
                httpClient: HTTPClient_Mock(),
                user: StreamVideo.mockUser,
                coordinatorInfo: CoordinatorInfo(
                    apiKey: StreamVideo.apiKey,
                    hostname: "test.com",
                    token: StreamVideo.mockToken.rawValue
                ),
                videoConfig: VideoConfig()
            ),
            videoConfig: VideoConfig(),
            audioSettings: AudioSettings(
                accessRequestEnabled: true,
                opusDtxEnabled: true,
                redundantCodingEnabled: true
            )
        )
        return webRTCClient
    }

}
