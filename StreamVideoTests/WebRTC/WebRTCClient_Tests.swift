//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import WebRTC
import XCTest

final class WebRTCClient_Tests: StreamVideoTestCase {
    
    private let callCid = "default:123"
    private let sessionId = "123"
    private let userId = "martin"
    private let callParticipant = CallParticipant(
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
        isPinned: false,
        audioLevel: 0, audioLevels: []
    )
    
    let mockResponseBuilder = MockResponseBuilder()
    
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
    
    private var webRTCClient: WebRTCClient!

    func test_webRTCClient_init_signalChannelIsUsingTheExpectedConnectURL() {
        // Given
        webRTCClient = makeWebRTCClient(ownCapabilities: [.sendAudio, .sendVideo])

        // Then
        XCTAssertEqual(webRTCClient.signalChannel?.connectURL.absoluteString, "wss://test.com/ws")
    }

    func test_webRTCClient_connectionFlow(
        ownCapabilities: [OwnCapability] = [.sendAudio, .sendVideo],
        migrating: Bool = false
    ) async throws {
        // Given
        webRTCClient = makeWebRTCClient(ownCapabilities: ownCapabilities)
        if migrating {
            webRTCClient.signalChannel?.connect()
            webRTCClient.prepareForMigration(
                url: "https://test.com",
                token: "123",
                webSocketURL: "ws://test/com",
                fromSfuName: "sfu-1"
            )
        }
        
        // When
        try await webRTCClient.connect(
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            connectOptions: ConnectOptions(iceServers: []),
            migrating: migrating
        )
        
        // Then
        var state = await webRTCClient.state.connectionState
        XCTAssert(state == .connecting)
        
        // When
        let engine = webRTCClient.signalChannel?.engine as! WebSocketEngine_Mock
        engine.simulateConnectionSuccess()
        
        // Then
        // Connection flow is not finished until join response arrives.
        state = await webRTCClient.state.connectionState
        XCTAssert(state == .connecting)
        
        // When
        let eventNotificationCenter = webRTCClient.eventNotificationCenter
        let event = Stream_Video_Sfu_Event_JoinResponse()
        eventNotificationCenter.process(.sfuEvent(.joinResponse(event)))
        try await waitForCallEvent()
        
        // Then
        state = await webRTCClient.state.connectionState
        XCTAssert(state == .connected)
    }
    
    func test_webRTCClient_migration() async throws {
        try await test_webRTCClient_connectionFlow(migrating: true)
    }
    
    func test_webRTCClient_defaultCallCapabilities() async throws {
        // Given
        try await test_webRTCClient_connectionFlow()
     
        // Then
        XCTAssert(webRTCClient.localAudioTrack != nil)
        XCTAssert(webRTCClient.localVideoTrack != nil)
    }
    
    func test_webRTCClient_callCapabilitiesNoAudioAndVideo() async throws {
        // Given
        try await test_webRTCClient_connectionFlow(ownCapabilities: [])
     
        // Then
        XCTAssert(webRTCClient.localAudioTrack == nil)
        XCTAssert(webRTCClient.localVideoTrack == nil)
    }
    
    func test_webRTCClient_cleanup() async throws {
        // Given
        try await test_webRTCClient_connectionFlow()
     
        // Then
        XCTAssert(webRTCClient.localAudioTrack != nil)
        XCTAssert(webRTCClient.localVideoTrack != nil)
        
        // When
        await webRTCClient.cleanUp()
        
        // Then
        XCTAssert(webRTCClient.localAudioTrack == nil)
        XCTAssert(webRTCClient.localVideoTrack == nil)
    }
    
    func test_webRTCClient_assignTracksMatchingTrackLookupPrefix() async throws {
        // Given
        try await test_webRTCClient_connectionFlow()
        var participant = participant.toCallParticipant()
        participant.trackLookupPrefix = "test-track"
        let track = await makeVideoTrack()
        
        // When
        await webRTCClient.state.update(tracks: ["test-track": track])
        await webRTCClient.state.update(callParticipant: participant)
        try await waitForCallEvent()
        
        // Then
        let callParticipant = await webRTCClient.state.callParticipants[participant.id]
        XCTAssert(callParticipant?.track != nil)
    }
    
    func test_webRTCClient_assignTracksMatchingId() async throws {
        // Given
        try await test_webRTCClient_connectionFlow()
        let participant = participant.toCallParticipant()
        let track = await makeVideoTrack()
        
        // When
        await webRTCClient.state.update(tracks: ["123": track])
        await webRTCClient.state.update(callParticipant: participant)
        try await waitForCallEvent()
        
        // Then
        let callParticipant = await webRTCClient.state.callParticipants[participant.id]
        XCTAssert(callParticipant?.track != nil)
    }
    
    func test_webRTCClient_assignTracksNoMatch() async throws {
        // Given
        try await test_webRTCClient_connectionFlow()
        let participant = participant.toCallParticipant()
        let track = await makeVideoTrack()
        
        // When
        await webRTCClient.state.update(tracks: ["test-track": track])
        await webRTCClient.state.update(callParticipant: participant)
        try await waitForCallEvent()
        
        // Then
        let callParticipant = await webRTCClient.state.callParticipants[participant.id]
        XCTAssert(callParticipant?.track == nil)
    }
    
    func test_webRTCClient_assignScreenSharingMatchingTrackLookupPrefix() async throws {
        // Given
        try await test_webRTCClient_connectionFlow()
        var participant = participant.toCallParticipant()
        participant.trackLookupPrefix = "test-track"
        let screensharingTrack = await makeVideoTrack()
        
        // When
        await webRTCClient.state.update(screensharingTracks: ["test-track": screensharingTrack])
        await webRTCClient.state.update(callParticipant: participant)
        try await waitForCallEvent()
        
        // Then
        let callParticipant = await webRTCClient.state.callParticipants[participant.id]
        XCTAssert(callParticipant?.screenshareTrack != nil)
    }
    
    func test_webRTCClient_assignScreenSharingMatchingId() async throws {
        // Given
        try await test_webRTCClient_connectionFlow()
        let participant = participant.toCallParticipant()
        let screensharingTrack = await makeVideoTrack()
        
        // When
        await webRTCClient.state.update(screensharingTracks: ["123": screensharingTrack])
        await webRTCClient.state.update(callParticipant: participant)
        try await waitForCallEvent()
        
        // Then
        let callParticipant = await webRTCClient.state.callParticipants[participant.id]
        XCTAssert(callParticipant?.screenshareTrack != nil)
    }

    func test_webRTCClient_participantJoinedAndLeft() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        
        // Then
        try await waitForCallEvent()
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.userId == userId)
        
        // When
        var participantLeft = Stream_Video_Sfu_Event_ParticipantLeft()
        participantLeft.callCid = callCid
        participantLeft.participant = participant
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantLeft(participantLeft)))
        
        // Then
        try await waitForCallEvent()
        let left = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNil(left)
    }
    
    func test_webRTCClient_dominantSpeakerChanged() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var dominantSpeakerChanged = Stream_Video_Sfu_Event_DominantSpeakerChanged()
        dominantSpeakerChanged.sessionID = sessionId
        dominantSpeakerChanged.userID = userId
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.dominantSpeakerChanged(dominantSpeakerChanged)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isDominantSpeaker == true)
    }
    
    func test_webRTCClient_audioLevelsChanged() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var audioLevelsChanged = Stream_Video_Sfu_Event_AudioLevelChanged()
        var audioLevel = Stream_Video_Sfu_Event_AudioLevel()
        audioLevel.sessionID = sessionId
        audioLevel.userID = userId
        audioLevel.isSpeaking = true
        audioLevelsChanged.audioLevels = [audioLevel]
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.audioLevelChanged(audioLevelsChanged)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isSpeaking == true)
    }
    
    func test_webRTCClient_connectionQualityChanged() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var connectionQualityChanged = Stream_Video_Sfu_Event_ConnectionQualityChanged()
        var update = Stream_Video_Sfu_Event_ConnectionQualityInfo()
        update.sessionID = sessionId
        update.userID = userId
        update.connectionQuality = .good
        connectionQualityChanged.connectionQualityUpdates = [update]
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.connectionQualityChanged(connectionQualityChanged)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.connectionQuality == .good)
    }
    
    func test_webRTCClient_joinResponse() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var joinResponse = Stream_Video_Sfu_Event_JoinResponse()
        joinResponse.callState.participants = [participant]
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.joinResponse(joinResponse)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.userId == userId)
    }
    
    func test_webRTCClient_audioTrackPublished() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var trackPublished = Stream_Video_Sfu_Event_TrackPublished()
        trackPublished.sessionID = sessionId
        trackPublished.userID = userId
        trackPublished.type = .audio
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackPublished(trackPublished)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasAudio == true)
    }
    
    func test_webRTCClient_videoTrackPublished() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var trackPublished = Stream_Video_Sfu_Event_TrackPublished()
        trackPublished.sessionID = sessionId
        trackPublished.userID = userId
        trackPublished.type = .video
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackPublished(trackPublished)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasVideo == true)
    }
    
    func test_webRTCClient_screenshareTrackPublished() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var trackPublished = Stream_Video_Sfu_Event_TrackPublished()
        trackPublished.sessionID = sessionId
        trackPublished.userID = userId
        trackPublished.type = .screenShare
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackPublished(trackPublished)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isScreensharing == true)
    }
    
    func test_webRTCClient_audioTrackUnpublished() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var trackUnpublished = Stream_Video_Sfu_Event_TrackUnpublished()
        trackUnpublished.sessionID = sessionId
        trackUnpublished.userID = userId
        trackUnpublished.type = .audio
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackUnpublished(trackUnpublished)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasAudio == false)
    }
    
    func test_webRTCClient_videoTrackUnpublished() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var trackUnpublished = Stream_Video_Sfu_Event_TrackUnpublished()
        trackUnpublished.sessionID = sessionId
        trackUnpublished.userID = userId
        trackUnpublished.type = .video
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackUnpublished(trackUnpublished)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.hasVideo == false)
    }
    
    func test_webRTCClient_screenshareTrackUnpublished() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        var trackUnpublished = Stream_Video_Sfu_Event_TrackUnpublished()
        trackUnpublished.sessionID = sessionId
        trackUnpublished.userID = userId
        trackUnpublished.type = .screenShare
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        try await waitForCallEvent()
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackUnpublished(trackUnpublished)))
        try await waitForCallEvent()
        
        // Then
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssert(newParticipant?.isScreensharing == false)
    }
    
    func test_webRTCClient_changeAudioState() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        let response = Stream_Video_Sfu_Signal_UpdateMuteStatesResponse()
        let data = try response.serializedData()
        httpClient.dataResponses = [data]
        webRTCClient = makeWebRTCClient(httpClient: httpClient)
        
        // When
        try await webRTCClient.connect(
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            connectOptions: ConnectOptions(iceServers: [])
        )
        try await webRTCClient.changeAudioState(isEnabled: false)
        
        // Then
        XCTAssert(webRTCClient.callSettings.audioOn == false)
    }
    
    func test_webRTCClient_changeVideoState() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        let response = Stream_Video_Sfu_Signal_UpdateMuteStatesResponse()
        let data = try response.serializedData()
        httpClient.dataResponses = [data]
        webRTCClient = makeWebRTCClient(httpClient: httpClient)
        
        // When
        try await webRTCClient.connect(
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            connectOptions: ConnectOptions(iceServers: [])
        )
        try await webRTCClient.changeVideoState(isEnabled: false)
        
        // Then
        XCTAssert(webRTCClient.callSettings.videoOn == false)
    }
    
    func test_webRTCClient_changeSoundState() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        
        // When
        try await webRTCClient.changeSoundState(isEnabled: false)
        
        // Then
        XCTAssert(webRTCClient.callSettings.audioOutputOn == false)
    }
    
    func test_webRTCClient_changeSpeakerState() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        
        // When
        try await webRTCClient.changeSpeakerState(isEnabled: false)
        
        // Then
        XCTAssert(webRTCClient.callSettings.speakerOn == false)
    }
    
    func test_webRTCClient_changeTrackVisibility() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let participants = ["123": callParticipant]
        await webRTCClient.state.update(callParticipants: participants)
        
        // When
        await webRTCClient.changeTrackVisibility(for: callParticipant, isVisible: true)
        
        // Then
        let updated = await webRTCClient.state.callParticipants[callParticipant.sessionId]
        XCTAssert(updated?.showTrack == true)
    }
    
    func test_webRTCClient_changeTrackVisibilityNonExisting() async throws {
        // Given
        webRTCClient = makeWebRTCClient()

        // When
        await webRTCClient.changeTrackVisibility(for: callParticipant, isVisible: true)
        
        // Then
        let updated = await webRTCClient.state.callParticipants[callParticipant.sessionId]
        XCTAssertNil(updated)
    }
    
    func test_webRTCClient_updateTrackSize() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let participants = ["123": callParticipant]
        await webRTCClient.state.update(callParticipants: participants)
        let trackSize = CGSize(width: 100, height: 100)
        
        // When
        await webRTCClient.updateTrackSize(trackSize, for: callParticipant)
        
        // Then
        let updated = await webRTCClient.state.callParticipants[callParticipant.sessionId]
        XCTAssert(updated?.trackSize == trackSize)
    }
    
    func test_webRTCClient_updateTrackSizeNonExisting() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        let trackSize = CGSize(width: 100, height: 100)
        
        // When
        await webRTCClient.updateTrackSize(trackSize, for: callParticipant)
        
        // Then
        let updated = await webRTCClient.state.callParticipants[callParticipant.sessionId]
        XCTAssertNil(updated)
    }
    
    // MARK: - private
    
    func makeWebRTCClient(
        ownCapabilities: [OwnCapability] = [],
        httpClient: HTTPClient? = nil
    ) -> WebRTCClient {
        let time = VirtualTime()
        VirtualTimeTimer.time = time
        var environment = WebSocketClient.Environment.mock
        environment.timerType = VirtualTimeTimer.self
        environment.httpClientBuilder = {
            httpClient ?? HTTPClient_Mock()
        }

        let webRTCClient = WebRTCClient(
            user: StreamVideo.mockUser,
            apiKey: StreamVideo.apiKey,
            hostname: "test.com",
            webSocketURLString: "wss://test.com/ws",
            token: StreamVideo.mockToken.rawValue,
            callCid: callCid,
            sessionID: nil,
            ownCapabilities: ownCapabilities,
            videoConfig: VideoConfig(),
            audioSettings: AudioSettings(
                accessRequestEnabled: true,
                defaultDevice: .speaker,
                micDefaultOn: true,
                opusDtxEnabled: true,
                redundantCodingEnabled: true,
                speakerDefaultOn: true
            ),
            environment: environment
        )
        return webRTCClient
    }
    
    private func makeVideoTrack() async -> RTCVideoTrack {
        let factory = PeerConnectionFactory()
        let videoSource = await factory.makeVideoSource(forScreenShare: false)
        let track = await factory.makeVideoTrack(source: videoSource)
        return track
    }

}
