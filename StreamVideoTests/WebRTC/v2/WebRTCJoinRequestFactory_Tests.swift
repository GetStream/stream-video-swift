//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class WebRTCJoinRequestFactory_Tests: XCTestCase, @unchecked Sendable {

    private static var videoConfig: VideoConfig! = .dummy()

    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private var subject: WebRTCJoinRequestFactory! = .init()

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        subject = nil
        mockCoordinatorStack = nil
        super.tearDown()
    }

    // MARK: - buildRequest

    func test_buildRequest_connectionTypeDefault_returnsCorrectJoinRequest() async throws {
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
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)

        let result = await subject.buildRequest(
            with: .default,
            coordinator: mockCoordinatorStack.coordinator,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertFalse(result.fastReconnect)
        XCTAssertEqual(result.token, token)
        XCTAssertEqual(result.reconnectDetails.announcedTracks, [])
        XCTAssertEqual(result.reconnectDetails.strategy, .unspecified)
        XCTAssertEqual(result.reconnectDetails.reconnectAttempt, 0)
        XCTAssertEqual(result.reconnectDetails.fromSfuID, "")
        XCTAssertEqual(result.reconnectDetails.subscriptions.count, 0)
        XCTAssertEqual(result.reconnectDetails.previousSessionID, "")
    }

    func test_buildRequest_connectionTypeFastReconnect_returnsCorrectJoinRequest() async throws {
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
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)

        let result = await subject.buildRequest(
            with: .fastReconnect,
            coordinator: mockCoordinatorStack.coordinator,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertTrue(result.fastReconnect)
        XCTAssertEqual(result.token, token)
        XCTAssertEqual(result.reconnectDetails.announcedTracks, [])
        XCTAssertEqual(result.reconnectDetails.strategy, .fast)
        XCTAssertEqual(result.reconnectDetails.reconnectAttempt, 12)
        XCTAssertEqual(result.reconnectDetails.fromSfuID, "")
        XCTAssertEqual(result.reconnectDetails.subscriptions.count, 0)
        XCTAssertEqual(result.reconnectDetails.previousSessionID, "")
    }

    func test_buildRequest_connectionTypeMigrate_returnsCorrectJoinRequest() async throws {
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
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)
        let fromSfuID = String.unique

        let result = await subject.buildRequest(
            with: .migration(fromHostname: fromSfuID),
            coordinator: mockCoordinatorStack.coordinator,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertFalse(result.fastReconnect)
        XCTAssertEqual(result.token, token)
        XCTAssertEqual(result.reconnectDetails.announcedTracks, [])
        XCTAssertEqual(result.reconnectDetails.strategy, .migrate)
        XCTAssertEqual(result.reconnectDetails.reconnectAttempt, 12)
        XCTAssertEqual(result.reconnectDetails.fromSfuID, fromSfuID)
        XCTAssertEqual(result.reconnectDetails.subscriptions.count, 0)
        XCTAssertEqual(result.reconnectDetails.previousSessionID, "")
    }

    func test_buildRequest_connectionTypeRejoin_returnsCorrectJoinRequest() async throws {
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
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(token: token)
        let previousSessionID = String.unique

        let result = await subject.buildRequest(
            with: .rejoin(fromSessionID: previousSessionID),
            coordinator: mockCoordinatorStack.coordinator,
            subscriberSdp: subscriberSdp,
            reconnectAttempt: 12,
            publisher: mockPublisher
        )

        XCTAssertEqual(result.sessionID, sessionId)
        XCTAssertEqual(result.subscriberSdp, subscriberSdp)
        XCTAssertFalse(result.fastReconnect)
        XCTAssertEqual(result.token, token)
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
        let mid = String.unique
        let mockTrack = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockAudioTrack()

        try await assertAnnouncedTracks(
            .audio,
            stubbedMid: [.audio: mid],
            stubbedTrack: [.audio: mockTrack]
        ) { result in
            XCTAssertEqual(result.count, 1)
            assertAnnouncedTrack(
                result[0],
                (
                    mid,
                    mockTrack
                ),
                videoCodecs: []
            )
        }
    }

    func test_buildAnnouncedTracks_publisherHasOnlyVideo_returnsCorrectTrackInfo() async throws {
        let mid = String.unique
        let mockTrack = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: false)

        try await assertAnnouncedTracks(
            .video,
            stubbedMid: [.video: mid],
            stubbedTrack: [.video: mockTrack]
        ) { result in
            XCTAssertEqual(result.count, 1)
            assertAnnouncedTrack(
                result[0],
                (
                    mid,
                    mockTrack
                ),
                videoCodecs: [.quarter, .half, .full]
            )
        }
    }

    func test_buildAnnouncedTracks_publisherHasOnlyScreenSharing_returnsCorrectTrackInfo() async throws {
        var videoOptions = VideoOptions()
        videoOptions.supportedCodecs = [.screenshare]
        let mid = String.unique
        let mockTrack = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: true)

        try await assertAnnouncedTracks(
            .screenshare,
            stubbedMid: [.screenshare: mid],
            stubbedTrack: [.screenshare: mockTrack]
        ) { result in
            XCTAssertEqual(result.count, 1)
            assertAnnouncedTrack(
                result[0],
                (
                    mid,
                    mockTrack
                ),
                videoCodecs: [.screenshare]
            )
        }
    }

    func test_buildAnnouncedTracks_publisherHasAllTracks_returnsCorrectTrackInfo() async throws {
        struct Entry { var type: TrackType; var mid: String; var track: RTCMediaStreamTrack }
        let entries = [
            Entry(
                type: .audio,
                mid: .unique,
                track: await mockCoordinatorStack
                    .coordinator
                    .stateAdapter
                    .peerConnectionFactory
                    .mockAudioTrack()
            ),
            
            Entry(
                type: .video,
                mid: .unique,
                track: await mockCoordinatorStack
                    .coordinator
                    .stateAdapter
                    .peerConnectionFactory
                    .mockVideoTrack(forScreenShare: false)
            ),
            
            Entry(
                type: .screenshare,
                mid: .unique,
                track: await mockCoordinatorStack
                    .coordinator
                    .stateAdapter
                    .peerConnectionFactory
                    .mockVideoTrack(forScreenShare: true)
            )
        ]

        let stubbedMid = entries.reduce(into: [TrackType: String]()) { $0[$1.type] = $1.mid }
        let stubbedTrack = entries.reduce(into: [TrackType: RTCMediaStreamTrack]()) { $0[$1.type] = $1.track }

        try await assertAnnouncedTracks(
            .screenshare,
            stubbedMid: stubbedMid,
            stubbedTrack: stubbedTrack
        ) { result in
            XCTAssertEqual(result.count, 3)
            assertAnnouncedTrack(
                result[0],
                (entries[0].mid, entries[0].track),
                videoCodecs: []
            )

            assertAnnouncedTrack(
                result[1],
                (entries[1].mid, entries[1].track),
                videoCodecs: [.quarter, .half, .full]
            )

            assertAnnouncedTrack(
                result[2],
                (entries[2].mid, entries[2].track),
                videoCodecs: [.screenshare]
            )
        }
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
            coordinator: mockCoordinatorStack.coordinator,
            incomingVideoQualitySettings: .none
        ).sorted { $0.sessionID <= $1.sessionID }

        XCTAssertEqual(result.count, 3)
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
        XCTAssertEqual(result[2].trackType, .screenShare)
    }

    // MARK: - Private helpers

    private func assertAnnouncedTracks(
        _ trackType: TrackType,
        stubbedMid: [TrackType: String] = [:],
        stubbedTrack: [TrackType: RTCMediaStreamTrack] = [:],
        isTrackEnabled: Bool = true,
        videoOptions: VideoOptions = .init(),
        handler: ([Stream_Video_Sfu_Models_TrackInfo]) -> Void
    ) async throws {
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockPublisher?.stubbedMid = stubbedMid
        mockPublisher?.stubbedTrack = stubbedTrack

        let result = subject.buildAnnouncedTracks(
            mockPublisher,
            videoOptions: videoOptions
        )

        handler(result)
    }

    private func assertAnnouncedTrack(
        _ actual: @autoclosure () -> Stream_Video_Sfu_Models_TrackInfo,
        _ expected: @autoclosure () -> (mid: String, track: RTCMediaStreamTrack),
        videoCodecs: [VideoCodec],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        switch actual().trackType {
        case .audio:
            XCTAssertEqual(actual().trackID, expected().track.trackId, file: file, line: line)
            XCTAssertEqual(actual().mid, expected().mid, file: file, line: line)
            XCTAssertEqual(actual().trackType, .audio, file: file, line: line)
            XCTAssertEqual(actual().muted, !expected().track.isEnabled, file: file, line: line)

        case .video:
            XCTAssertEqual(actual().trackID, expected().track.trackId, file: file, line: line)
            XCTAssertEqual(actual().mid, expected().mid, file: file, line: line)
            XCTAssertEqual(actual().trackType, .video, file: file, line: line)
            XCTAssertEqual(actual().muted, !expected().track.isEnabled, file: file, line: line)

            XCTAssertEqual(actual().layers.count, videoCodecs.count)
            for (index, codec) in videoCodecs.enumerated() {
                XCTAssertEqual(actual().layers[index].bitrate, .init(codec.maxBitrate))
                XCTAssertEqual(actual().layers[index].fps, 30)
                XCTAssertEqual(actual().layers[index].quality, codec.sfuQuality)
                XCTAssertEqual(actual().layers[index].videoDimension.width, .init(codec.dimensions.width))
                XCTAssertEqual(actual().layers[index].videoDimension.height, .init(codec.dimensions.height))
            }

        case .screenShare:
            XCTAssertEqual(actual().trackID, expected().track.trackId, file: file, line: line)
            XCTAssertEqual(actual().mid, expected().mid, file: file, line: line)
            XCTAssertEqual(actual().trackType, .screenShare, file: file, line: line)
            XCTAssertEqual(actual().muted, !expected().track.isEnabled, file: file, line: line)

            XCTAssertEqual(actual().layers.count, videoCodecs.count)
            for (index, codec) in videoCodecs.enumerated() {
                XCTAssertEqual(actual().layers[index].bitrate, .init(codec.maxBitrate))
                XCTAssertEqual(actual().layers[index].fps, 15)
                XCTAssertEqual(actual().layers[index].quality, codec.sfuQuality)
                XCTAssertEqual(actual().layers[index].videoDimension.width, .init(codec.dimensions.width))
                XCTAssertEqual(actual().layers[index].videoDimension.height, .init(codec.dimensions.height))
            }

        default:
            XCTFail()
        }
    }
}
