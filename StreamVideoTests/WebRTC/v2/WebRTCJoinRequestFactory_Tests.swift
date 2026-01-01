//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class WebRTCJoinRequestFactory_Tests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private var subject: WebRTCJoinRequestFactory! = .init(capabilities: [])

    // MARK: - Lifecycle

    override class func tearDown() {
        videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        subject = nil
        mockCoordinatorStack = nil
        super.tearDown()
    }

    // MARK: - buildRequest

    func test_buildRequest_connectionTypeDefault_returnsCorrectJoinRequest() async throws {
        let publisherSdp = String.unique
        let subscriberSdp = String.unique
        let token = String.unique
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let sessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .sessionID
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)

        let result = await subject.buildRequest(
            with: .default,
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.unifiedSessionID, unifiedSessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertFalse(result.fastReconnect)
        XCTAssertEqual(result.token, token)
        XCTAssertEqual(result.source, .webrtcUnspecified)
        XCTAssertEqual(result.reconnectDetails.announcedTracks, [])
        XCTAssertEqual(result.reconnectDetails.strategy, .unspecified)
        XCTAssertEqual(result.reconnectDetails.reconnectAttempt, 0)
        XCTAssertEqual(result.reconnectDetails.fromSfuID, "")
        XCTAssertEqual(result.reconnectDetails.subscriptions.count, 0)
        XCTAssertEqual(result.reconnectDetails.previousSessionID, "")
    }

    func test_buildRequest_connectionTypeFastReconnect_returnsCorrectJoinRequest() async throws {
        let publisherSdp = String.unique
        let subscriberSdp = String.unique
        let token = String.unique
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let sessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .sessionID
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)

        let result = await subject.buildRequest(
            with: .fastReconnect,
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.unifiedSessionID, unifiedSessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertTrue(result.fastReconnect)
        XCTAssertEqual(result.token, token)
        XCTAssertEqual(result.source, .webrtcUnspecified)
        XCTAssertEqual(result.reconnectDetails.announcedTracks, [])
        XCTAssertEqual(result.reconnectDetails.strategy, .fast)
        XCTAssertEqual(result.reconnectDetails.reconnectAttempt, 12)
        XCTAssertEqual(result.reconnectDetails.fromSfuID, "")
        XCTAssertEqual(result.reconnectDetails.subscriptions.count, 0)
        XCTAssertEqual(result.reconnectDetails.previousSessionID, "")
    }

    func test_buildRequest_connectionTypeMigrate_returnsCorrectJoinRequest() async throws {
        let publisherSdp = String.unique
        let subscriberSdp = String.unique
        let token = String.unique
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let sessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .sessionID
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)
        let fromSfuID = String.unique

        let result = await subject.buildRequest(
            with: .migration(fromHostname: fromSfuID),
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.unifiedSessionID, unifiedSessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertFalse(result.fastReconnect)
        XCTAssertEqual(result.token, token)
        XCTAssertEqual(result.source, .webrtcUnspecified)
        XCTAssertEqual(result.reconnectDetails.announcedTracks, [])
        XCTAssertEqual(result.reconnectDetails.strategy, .migrate)
        XCTAssertEqual(result.reconnectDetails.reconnectAttempt, 12)
        XCTAssertEqual(result.reconnectDetails.fromSfuID, fromSfuID)
        XCTAssertEqual(result.reconnectDetails.subscriptions.count, 0)
        XCTAssertEqual(result.reconnectDetails.previousSessionID, "")
    }

    func test_buildRequest_connectionTypeRejoin_returnsCorrectJoinRequest() async throws {
        let publisherSdp = String.unique
        let subscriberSdp = String.unique
        let token = String.unique
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let sessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .sessionID
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)
        let previousSessionID = String.unique

        let result = await subject.buildRequest(
            with: .rejoin(fromSessionID: previousSessionID),
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.unifiedSessionID, unifiedSessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertFalse(result.fastReconnect)
        XCTAssertEqual(result.token, token)
        XCTAssertEqual(result.source, .webrtcUnspecified)
        XCTAssertEqual(result.reconnectDetails.announcedTracks, [])
        XCTAssertEqual(result.reconnectDetails.strategy, .rejoin)
        XCTAssertEqual(result.reconnectDetails.reconnectAttempt, 12)
        XCTAssertEqual(result.reconnectDetails.fromSfuID, "")
        XCTAssertEqual(result.reconnectDetails.subscriptions.count, 0)
        XCTAssertEqual(result.reconnectDetails.previousSessionID, previousSessionID)
    }

    // MARK: - buildReconnectDetails

    func test_buildReconnectDetails_connectionTypeDefault_returnsCorrectReconnectDetails() async throws {
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        let result = await subject.buildReconnectDetails(
            for: .default,
            coordinator: mockCoordinatorStack.coordinator,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result?.strategy, .unspecified)
        XCTAssertEqual(result?.reconnectAttempt, 0)
        XCTAssertEqual(result?.fromSfuID, "")
        XCTAssertEqual(result?.subscriptions.count, 0)
        XCTAssertEqual(result?.previousSessionID, "")
    }

    func test_buildReconnectDetails_connectionTypeFastReconnect_returnsCorrectReconnectDetails() async throws {
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockPublisher?.stubbedMid[.audio] = "audio"
        mockPublisher?.stubbedTrack[.audio] = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockAudioTrack()

        let result = await subject.buildReconnectDetails(
            for: .fastReconnect,
            coordinator: mockCoordinatorStack.coordinator,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result?.strategy, .fast)
        XCTAssertEqual(result?.reconnectAttempt, 12)
        XCTAssertEqual(result?.fromSfuID, "")
        XCTAssertEqual(result?.subscriptions.count, 0)
        XCTAssertEqual(result?.previousSessionID, "")
    }

    func test_buildReconnectDetails_connectionTypeFastMigration_returnsCorrectReconnectDetails() async throws {
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockPublisher?.stubbedMid[.audio] = "audio"
        mockPublisher?.stubbedTrack[.audio] = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockAudioTrack()
        let fromSfuID = String.unique

        let result = await subject.buildReconnectDetails(
            for: .migration(fromHostname: fromSfuID),
            coordinator: mockCoordinatorStack.coordinator,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result?.strategy, .migrate)
        XCTAssertEqual(result?.reconnectAttempt, 12)
        XCTAssertEqual(result?.fromSfuID, fromSfuID)
        XCTAssertEqual(result?.subscriptions.count, 0)
        XCTAssertEqual(result?.previousSessionID, "")
    }

    func test_buildReconnectDetails_connectionTypeFastRejoin_returnsCorrectReconnectDetails() async throws {
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockPublisher?.stubbedMid[.audio] = "audio"
        mockPublisher?.stubbedTrack[.audio] = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockAudioTrack()
        let fromSessionID = String.unique

        let result = await subject.buildReconnectDetails(
            for: .rejoin(fromSessionID: fromSessionID),
            coordinator: mockCoordinatorStack.coordinator,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result?.strategy, .rejoin)
        XCTAssertEqual(result?.reconnectAttempt, 12)
        XCTAssertEqual(result?.fromSfuID, "")
        XCTAssertEqual(result?.subscriptions.count, 0)
        XCTAssertEqual(result?.previousSessionID, fromSessionID)
    }

    // MARK: - buildAnnouncedTracks

    func test_buildAnnouncedTracks_publisherHasOnlyAudio_returnsCorrectTrackInfo() async throws {
        try await assertAnnouncedTracks(
            .audio,
            expected: [.audio: [
                .dummy(trackID: "audio-0", trackType: .audio, mid: "0"),
                .dummy(trackID: "audio-1", trackType: .audio, mid: "1")
            ]]
        )
    }

    func test_buildAnnouncedTracks_publisherHasOnlyVideo_returnsCorrectTrackInfo() async throws {
        try await assertAnnouncedTracks(
            .audio,
            expected: [.video: [
                .dummy(
                    trackID: "video-0",
                    trackType: .video,
                    layers: [.dummy(rid: "q"), .dummy(rid: "h")],
                    mid: "0"
                ),
                .dummy(
                    trackID: "video-1",
                    trackType: .video,
                    layers: [.dummy(rid: "q")],
                    mid: "1"
                )
            ]]
        )
    }

    func test_buildAnnouncedTracks_publisherHasOnlyScreenSharing_returnsCorrectTrackInfo() async throws {
        try await assertAnnouncedTracks(
            .audio,
            expected: [.screenshare: [
                .dummy(
                    trackID: "screenShare-0",
                    trackType: .screenShare,
                    layers: [.dummy(rid: "q"), .dummy(rid: "h")],
                    mid: "0"
                ),
                .dummy(
                    trackID: "video-1",
                    trackType: .screenShare,
                    layers: [.dummy(rid: "q")],
                    mid: "1"
                )
            ]]
        )
    }

    func test_buildAnnouncedTracks_publisherHasAllTracks_returnsCorrectTrackInfo() async throws {
        try await assertAnnouncedTracks(
            .audio,
            expected: [
                .audio: [
                    .dummy(
                        trackID: "audio-0",
                        trackType: .audio,
                        mid: "0"
                    )
                ],
                .video: [
                    .dummy(
                        trackID: "video-1",
                        trackType: .video,
                        layers: [.dummy(rid: "h")],
                        mid: "1"
                    )
                ],
                .screenshare: [
                    .dummy(
                        trackID: "screenShare-0",
                        trackType: .screenShare,
                        layers: [.dummy(rid: "q"), .dummy(rid: "h")],
                        mid: "0"
                    )
                ]
            ]
        )
    }

    // MARK: - buildSubscriptionDetails

    func test_buildSubscriptionDetails_returnsTrackSubscriptionDetailsForParticipantsOtherThanLocal() async throws {
        _ = mockCoordinatorStack.coordinator
        let sessionId = try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        await mockCoordinatorStack.coordinator.stateAdapter.enqueue { _ in
            [
                sessionId: .dummy(id: sessionId, hasVideo: true, hasAudio: true, isScreenSharing: true),
                "1": .dummy(id: "1", hasVideo: true, trackSize: .init(width: 10, height: 11)),
                "2": .dummy(id: "2", hasAudio: true),
                "3": .dummy(id: "3", isScreenSharing: true)
            ]
        }

        await fulfillment {
            await self
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .participants.count == 4
        }

        let result = await subject.buildSubscriptionDetails(
            .unique,
            sessionID: mockCoordinatorStack.coordinator.stateAdapter.sessionID,
            participants: Array(mockCoordinatorStack.coordinator.stateAdapter.participants.values),
            incomingVideoQualitySettings: .none
        ).sorted { $0.sessionID <= $1.sessionID }

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].userID, "1")
        XCTAssertEqual(result[0].sessionID, "1")
        XCTAssertEqual(result[0].trackType, .video)
        XCTAssertEqual(result[0].dimension.width, 10)
        XCTAssertEqual(result[0].dimension.height, 11)
        XCTAssertEqual(result[1].userID, "2")
        XCTAssertEqual(result[1].sessionID, "2")
        XCTAssertEqual(result[1].trackType, .audio)
        XCTAssertEqual(result[2].userID, "3")
        XCTAssertEqual(result[2].sessionID, "3")
        XCTAssertEqual(result[2].trackType, .screenShareAudio)
        XCTAssertEqual(result[3].userID, "3")
        XCTAssertEqual(result[3].sessionID, "3")
        XCTAssertEqual(result[3].trackType, .screenShare)
    }

    // MARK: - buildPreferredPublishOptions

    func test_buildPreferredPublishOptions_withValidSDP() async throws {
        let publisherSdp =
            "v=0\r\no=- 46117317 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=rtpmap:96 opus/48000/2\r\na=rtpmap:97 VP8/90000"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(
                publishOptions: .init(
                    audio: [.dummy(codec: .opus)],
                    video: [.dummy(codec: .vp8)]
                )
            )

        let result = await subject.buildPreferredPublishOptions(
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].codec.name, "opus")
        XCTAssertEqual(result[0].codec.payloadType, 96)
        XCTAssertEqual(result[1].codec.name, "vp8")
        XCTAssertEqual(result[1].codec.payloadType, 97)
    }

    func test_buildPreferredPublishOptions_withInvalidSDP() async throws {
        let publisherSdp = "v=0\r\no=- 46117317 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=invalid:96 opus/48000/2"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(publishOptions: .init(audio: [.dummy(codec: .opus)]))

        let result = await subject.buildPreferredPublishOptions(
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].codec.name, "opus")
        XCTAssertEqual(result[0].codec.payloadType, 0)
    }

    func test_buildPreferredPublishOptions_withEmptySDP() async throws {
        let publisherSdp = ""
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(publishOptions: .init(audio: [.dummy(codec: .opus)]))

        let result = await subject.buildPreferredPublishOptions(
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].codec.name, "opus")
        XCTAssertEqual(result[0].codec.payloadType, 0)
    }

    func test_buildPreferredPublishOptions_withMultipleCodecs() async throws {
        let publisherSdp =
            "v=0\r\no=- 46117317 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=rtpmap:96 opus/48000/2\r\na=rtpmap:97 VP8/90000\r\na=rtpmap:98 H264/90000"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(publishOptions: .init(
                audio: [.dummy(codec: .opus)],
                video: [.dummy(codec: .vp8), .dummy(codec: .h264)]
            ))

        let result = await subject.buildPreferredPublishOptions(
            coordinator: mockCoordinatorStack.coordinator,
            publisherSdp: publisherSdp
        )

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].codec.name, "opus")
        XCTAssertEqual(result[0].codec.payloadType, 96)
        XCTAssertEqual(result[1].codec.name, "vp8")
        XCTAssertEqual(result[1].codec.payloadType, 97)
        XCTAssertEqual(result[2].codec.name, "h264")
        XCTAssertEqual(result[2].codec.payloadType, 98)
    }

    // MARK: - Private helpers

    private func assertAnnouncedTracks(
        _ trackType: TrackType,
        expected: [TrackType: [Stream_Video_Sfu_Models_TrackInfo]],
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockPublisher?.stubbedTrackInfo = expected

        let result = subject.buildAnnouncedTracks(mockPublisher, collectionType: .allAvailable)
        let expected: [Stream_Video_Sfu_Models_TrackInfo] = (expected[.audio] ?? [])
            + (expected[.video] ?? [])
            + (expected[.screenshare] ?? [])

        XCTAssertEqual(result, expected, file: file, line: line)
    }
}
