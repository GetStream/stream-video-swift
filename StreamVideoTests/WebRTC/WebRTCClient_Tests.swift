//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import StreamWebRTC
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
        audioLevel: 0,
        audioLevels: [],
        pin: nil
    )
    
    let mockResponseBuilder = MockResponseBuilder()
    
    private lazy var participant: Stream_Video_Sfu_Models_Participant = {
        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = userId
        participant.sessionID = sessionId
        participant.name = "Test"
        return participant
    }()

    private lazy var participantJoined: Stream_Video_Sfu_Event_ParticipantJoined = {
        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = callCid
        participantJoined.participant = participant
        return participantJoined
    }()

    private lazy var factory: PeerConnectionFactory! = PeerConnectionFactory(audioProcessingModule: MockAudioProcessingModule())
    private var webRTCClient: WebRTCClient!
    private var tracks: Set<RTCVideoTrack> = []

    // MARK: - Lifecycle

    override func tearDown() {
        tracks.forEach { $0.isEnabled = false }
        factory = nil
        webRTCClient = nil
        super.tearDown()
    }

    // MARK: init

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
        let track = makeVideoTrack()
        
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
        let track = makeVideoTrack()
        
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
        let track = makeVideoTrack()
        
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
        let screensharingTrack = makeVideoTrack()
        
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
        let screensharingTrack = makeVideoTrack()
        
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
    
    func test_webRTCClient_participantJoinedAndUpdated() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        
        // Then
        try await waitForCallEvent()
        let newParticipant = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(newParticipant)
        XCTAssertEqual(newParticipant?.userId, userId)
        XCTAssertEqual(newParticipant?.name, "Test")
        
        // When
        var participantUpdated = Stream_Video_Sfu_Event_ParticipantUpdated()
        participantUpdated.callCid = callCid
        var updatedParticipant = participant
        updatedParticipant.name = "Test 1"
        participantUpdated.participant = updatedParticipant
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantUpdated(participantUpdated)))
        
        // Then
        try await waitForCallEvent()
        let updated = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.userId, userId)
        XCTAssertEqual(updated?.name, "Test 1")
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
        webRTCClient
            .eventNotificationCenter
            .process(.sfuEvent(.participantJoined(participantJoined)))
        webRTCClient
            .eventNotificationCenter
            .process(.sfuEvent(.connectionQualityChanged(connectionQualityChanged)))

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
    
    func test_webRTCClient_iceTrickleSubscriber() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        try await test_webRTCClient_connectionFlow()
        let trickleEvent = try makeIceTrickleEvent(peerType: .subscriber)
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.iceTrickle(trickleEvent)))
        try await waitForCallEvent()

        // Then
        XCTAssert(webRTCClient.subscriber?.pendingIceCandidates.count == 1)
    }
    
    func test_webRTCClient_iceTricklePublisher() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        try await test_webRTCClient_connectionFlow()
        let trickleEvent = try makeIceTrickleEvent(peerType: .publisherUnspecified)
        
        // When
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.iceTrickle(trickleEvent)))
        try await waitForCallEvent()

        // Then
        XCTAssert(webRTCClient.publisher?.pendingIceCandidates.count == 1)
    }
    
    func test_webRTCClient_changePublishQuality() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        try await test_webRTCClient_connectionFlow()
        var event = Stream_Video_Sfu_Event_ChangePublishQuality()
        var videoSender = Stream_Video_Sfu_Event_VideoSender()
        var layer = Stream_Video_Sfu_Event_VideoLayerSetting()
        layer.active = true
        layer.name = "test"
        videoSender.layers = [layer]
        event.videoSenders = [videoSender]
        let videoOptions = VideoOptions()
        var encodingParams = [RTCRtpEncodingParameters]()
        for codec in videoOptions.supportedCodecs {
            let encodingParam = RTCRtpEncodingParameters()
            encodingParam.rid = codec.quality
            encodingParam.maxBitrateBps = (codec.maxBitrate) as NSNumber
            if let scaleDownFactor = codec.scaleDownFactor {
                encodingParam.scaleResolutionDownBy = (scaleDownFactor) as NSNumber
            }
            encodingParams.append(encodingParam)
        }
        
        // When
        let videoTrack = makeVideoTrack()
        webRTCClient
            .publisher?
            .addTransceiver(
                videoTrack,
                streamIds: ["some-id"],
                trackType: .video
            )

        webRTCClient
            .eventNotificationCenter
            .process(.sfuEvent(.changePublishQuality(event)))

        let expected = encodingParams.map(\.rid)
        await fulfillment { [weak webRTCClient] in
            let actual = webRTCClient?
                .publisher?
                .transceiver?
                .sender
                .parameters
                .encodings
                .map(\.rid)

            return actual == expected
        }
    }
    
    func test_webRTCClient_screensharingBroadcast() async throws {
        try await assert_webRTCClient_screensharing(type: .broadcast)
    }
    
    func test_webRTCClient_screensharingInApp() async throws {
        try await assert_webRTCClient_screensharing(type: .inApp)
    }
    
    func assert_webRTCClient_screensharing(type: ScreensharingType) async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        let response = Stream_Video_Sfu_Signal_UpdateMuteStatesResponse()
        for _ in 0..<20 {
            let data = try response.serializedData()
            httpClient.dataResponses.append(data)
        }
        webRTCClient = makeWebRTCClient(
            ownCapabilities: [.screenshare],
            httpClient: httpClient
        )
        let sessionId = "123"
        let participants = [sessionId: callParticipant]
        await webRTCClient.state.update(callParticipants: participants)
        
        // When
        try await webRTCClient.connect(
            callSettings: CallSettings(),
            videoOptions: VideoOptions(),
            connectOptions: ConnectOptions(iceServers: [])
        )
        try? await webRTCClient.startScreensharing(type: type)
        var event = Stream_Video_Sfu_Event_TrackPublished()
        event.sessionID = sessionId
        event.type = .screenShare
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackPublished(event)))
        try await waitForCallEvent()
        
        // Then
        var current = await webRTCClient.state.callParticipants
        XCTAssert(current.values.first?.isScreensharing == true)
        
        // When
        try await webRTCClient.stopScreensharing()
        var unpublished = Stream_Video_Sfu_Event_TrackUnpublished()
        unpublished.sessionID = sessionId
        unpublished.type = .screenShare
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.trackUnpublished(unpublished)))
        try await waitForCallEvent()
        
        // Then
        current = await webRTCClient.state.callParticipants
        XCTAssert(current.values.first?.isScreensharing == false)
    }
    
    func test_webRTCClient_pinEvents() async throws {
        // Given
        webRTCClient = makeWebRTCClient()
        try await test_webRTCClient_connectionFlow()
        let sessionId = "123"
        let participants = [sessionId: callParticipant]
        await webRTCClient.state.update(callParticipants: participants)
        
        // When
        var event = Stream_Video_Sfu_Event_PinsChanged()
        var pin = Stream_Video_Sfu_Models_Pin()
        pin.sessionID = sessionId
        event.pins = [pin]
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.pinsUpdated(event)))
        try await waitForCallEvent()
        
        // Then
        var current = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNotNil(current?.pin)
        XCTAssertEqual(current?.pin?.isLocal, false)
        
        // When
        event = Stream_Video_Sfu_Event_PinsChanged()
        event.pins = []
        webRTCClient.eventNotificationCenter.process(.sfuEvent(.pinsUpdated(event)))
        try await waitForCallEvent()
        
        // Then
        current = await webRTCClient.state.callParticipants[sessionId]
        XCTAssertNil(current?.pin)
    }
    
    // MARK: - private
    
    func makeWebRTCClient(
        ownCapabilities: [OwnCapability] = [],
        httpClient: HTTPClient? = nil
    ) -> WebRTCClient {
        var environment = WebSocketClient.Environment.mock
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
            videoConfig: .dummy(),
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
    
    private func makeIceTrickleEvent(
        peerType: Stream_Video_Sfu_Models_PeerType
    ) throws -> Stream_Video_Sfu_Models_ICETrickle {
        let iceCandidate = try JSONSerialization.data(withJSONObject: ["candidate": "test-sdp"])
        let iceCandidateString = String(data: iceCandidate, encoding: .utf8)!
        var trickleEvent = Stream_Video_Sfu_Models_ICETrickle()
        trickleEvent.iceCandidate = iceCandidateString
        trickleEvent.peerType = peerType
        return trickleEvent
    }
    
    private func makeVideoTrack() -> RTCVideoTrack {
        let videoSource = factory.makeVideoSource(forScreenShare: false)
        let track = factory.makeVideoTrack(source: videoSource)
        tracks.insert(track)
        return track
    }
}
