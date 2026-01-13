//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class WebRTCStateAdapter_Tests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var user: User! = .dummy()
    private lazy var apiKey: String! = .unique
    private lazy var callCid: String! = .unique
    private lazy var callSettings: CallSettings! = .default
    private lazy var mockPeerConnectionFactory: PeerConnectionFactory! = .build(
        audioProcessingModule: Self.videoConfig.audioProcessingModule,
        audioDeviceModuleSource: MockRTCAudioDeviceModule()
    )
    private lazy var rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory! =
        .init(peerConnectionFactory: mockPeerConnectionFactory)
    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var mockAudioStore: MockRTCAudioStore! = .init()
    private lazy var subject: WebRTCStateAdapter! = .init(
        user: user,
        apiKey: apiKey,
        callCid: callCid,
        videoConfig: Self.videoConfig,
        callSettings: callSettings,
        peerConnectionFactory: mockPeerConnectionFactory,
        rtcPeerConnectionCoordinatorFactory: rtcPeerConnectionCoordinatorFactory
    )

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        mockAudioStore.makeShared()
        _ = mockPermissions
    }

    override func tearDown() async throws {
        await subject.cleanUp()
        mockAudioStore.dismantle()
        mockPermissions.dismantle()
        subject = nil
        callSettings = nil
        mockPermissions = nil
        callCid = nil
        apiKey = nil
        user = nil
        mockPeerConnectionFactory = nil
        try await super.tearDown()
    }

    override class func tearDown() {
        videoConfig = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_callSettingsWereSetCorrectly() async {
        let callSettings = CallSettings(
            audioOn: false,
            videoOn: false,
            cameraPosition: .back
        )
        self.callSettings = callSettings

        _ = subject

        await assertEqualAsync(
            await subject.callSettings,
            callSettings
        )
    }

    // MARK: - setSessionID

    func test_sessionID_shouldNotBeEmptyOnInit() async throws {
        await assertEqualAsync(await subject.sessionID.isEmpty, false)
    }

    func test_setSessionID_shouldUpdateSessionID() async throws {
        _ = subject
        _ = try await subject
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        let expected = String.unique

        await subject.set(sessionID: expected)

        await assertEqualAsync(await subject.sessionID, expected)
    }

    // MARK: - setIsTracingEnabled

    func test_setIsTracingEnabled_shouldUpdateIsTracingEnabled() async throws {
        let expected = true

        await subject.set(isTracingEnabled: expected)

        await assertEqualAsync(await subject.isTracingEnabled, expected)
    }

    // MARK: - setCallSettings

    func test_setCallSettings_shouldUpdateCallSettings() async throws {
        let expected = CallSettings(cameraPosition: .back)

        await subject.enqueueCallSettings { _ in expected }

        await fulfillment {
            let currentValue = await self.subject.callSettings
            return currentValue == expected
        }
    }

    // MARK: - setInitialCallSettings

    func test_setInitialCallSettings_shouldUpdateInitialCallSettings() async throws {
        let expected = CallSettings(cameraPosition: .back)

        await subject.set(initialCallSettings: expected)

        await assertEqualAsync(await subject.initialCallSettings, expected)
    }

    // MARK: - setAudioSettings

    func test_setAudioSettings_shouldUpdateAudioSettings() async throws {
        let expected = AudioSettings(
            accessRequestEnabled: false,
            defaultDevice: .speaker,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: true
        )

        await subject.set(audioSettings: expected)

        await assertEqualAsync(await subject.audioSettings, expected)
    }

    // MARK: - setVideoOptions

    func test_setVideoOptions_shouldUpdateVideoOptions() async throws {
        let expected = VideoOptions(
            preferredCameraPosition: .back
        )

        await subject.set(videoOptions: expected)

        await assertEqualAsync(await subject.videoOptions.preferredCameraPosition, expected.preferredCameraPosition)
    }

    // MARK: - setPublishOptions

    func test_setPublishOptions_shouldUpdatePublishOptions() async throws {
        let expected = PublishOptions(
            video: [.dummy(codec: .av1)]
        )

        await subject.set(publishOptions: expected)

        await assertEqualAsync(await subject.publishOptions, expected)
    }

    // MARK: - setConnectOptions

    func test_setConnectOptions_shouldUpdateConnectOptions() async throws {
        let expected = ConnectOptions(
            iceServers: [
                .init(password: .unique, urls: [.unique], username: .unique)
            ]
        )

        await subject.set(connectOptions: expected)

        await assertEqualAsync(
            await subject.connectOptions.rtcConfiguration.iceServers.map {
                ICEServer(
                    password: $0.credential ?? .unique,
                    urls: $0.urlStrings,
                    username: $0.username ?? .unique
                )
            },
            expected.rtcConfiguration.iceServers.map {
                ICEServer(
                    password: $0.credential ?? .unique,
                    urls: $0.urlStrings,
                    username: $0.username ?? .unique
                )
            }
        )
    }

    // MARK: - setOwnCapabilities

    func test_setOwnCapabilities_shouldUpdateOwnCapabilities() async throws {
        let expected = Set<OwnCapability>([OwnCapability.blockUsers, .removeCallMember])

        await subject.set(ownCapabilities: expected)

        await assertEqualAsync(await subject.ownCapabilities, expected)
    }

    // MARK: - setStatsAdapter

    func test_setStatsReporter_shouldUpdateStatsAdapter() async throws {
        let expected = WebRTCStatsAdapter(
            sessionID: .unique,
            unifiedSessionID: .unique,
            isTracingEnabled: true,
            trackStorage: await subject.trackStorage
        )

        await subject.set(statsAdapter: expected)

        await assertTrueAsync(await subject.statsAdapter === expected)
    }

    // MARK: - setSFUAdapter

    func test_setSFUAdapter_shouldUpdateSFUAdapterAndStatsReporter() async throws {
        let statsAdapter = WebRTCStatsAdapter(
            sessionID: .unique,
            unifiedSessionID: .unique,
            isTracingEnabled: true,
            trackStorage: await subject.trackStorage
        )
        await subject.set(statsAdapter: statsAdapter)
        let mockSFUStack = MockSFUStack()

        await subject.set(sfuAdapter: mockSFUStack.adapter)

        await assertTrueAsync(await subject.sfuAdapter === mockSFUStack.adapter)
        XCTAssertTrue(statsAdapter.sfuAdapter === mockSFUStack.adapter)
    }

    // MARK: - setParticipantsCount

    func test_setParticipantsCount_shouldUpdateParticipantsCount() async throws {
        let expected = UInt32(32)

        await subject.set(participantsCount: expected)

        await assertEqualAsync(await subject.participantsCount, expected)
    }

    // MARK: - setAnonymousCount

    func test_setAnonymousCount_shouldUpdateAnonymousCount() async throws {
        let expected = UInt32(32)

        await subject.set(anonymousCount: expected)

        await assertEqualAsync(await subject.anonymousCount, expected)
    }

    // MARK: - setParticipantPins

    func test_setParticipantPins_shouldUpdateParticipantPins() async throws {
        let expected = [PinInfo(isLocal: true, pinnedAt: .init(timeIntervalSince1970: 100))]

        await subject.set(participantPins: expected)

        await assertEqualAsync(await subject.participantPins, expected)
    }

    // MARK: - setToken

    func test_setToken_shouldUpdateToken() async throws {
        let expected = String.unique

        await subject.set(token: expected)

        await assertEqualAsync(await subject.token, expected)
    }

    // MARK: - setIncomingVideoQualitySettings

    func test_setIncomingVideoQualitySettings_shouldUpdateIncomingVideoQualitySettings() async throws {
        let expected = IncomingVideoQualitySettings.manual(
            group: .custom(sessionIds: [.unique, .unique]),
            targetSize: .init(
                width: 11,
                height: 10
            )
        )

        await subject.set(incomingVideoQualitySettings: expected)

        await assertEqualAsync(await subject.incomingVideoQualitySettings, expected)
    }

    // MARK: - setVideoFilter

    func test_setVideoFilter_shouldUpdateVideoFilter() async throws {
        let sfuStack = MockSFUStack()
        await subject.set(sfuAdapter: sfuStack.adapter)
        try await subject.configurePeerConnections()
        let expected = VideoFilter(id: .unique, name: .unique, filter: { _ in fatalError() })

        await subject.set(videoFilter: expected)

        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.first?.id,
            expected.id
        )
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.first?.name,
            expected.name
        )
    }

    // MARK: - clientCapabilities

    func test_clientCapabilities_expectedDefaultValue() async throws {
        await assertEqualAsync(
            await subject.clientCapabilities,
            [.subscriberVideoPause]
        )
    }

    // MARK: - enableClientCapabilities

    func enableClientCapabilities_shouldUpdateClientCapabilities() async throws {

        await subject.enableClientCapabilities([.subscriberVideoPause])

        await assertEqualAsync(await subject.clientCapabilities, [.subscriberVideoPause])
    }

    // MARK: - disableClientCapabilities

    func test_enableClientCapabilities_shouldUpdateClientCapabilities() async throws {

        await subject.enableClientCapabilities([.subscriberVideoPause])

        await subject.disableClientCapabilities([.subscriberVideoPause])

        await assertEqualAsync(await subject.clientCapabilities, [])
    }

    // MARK: - refreshSession

    func test_refreshSession_shouldUpdateSessionID() async throws {
        let currentSessionId = await subject.sessionID

        await subject.refreshSession()

        let newSessionId = await subject.sessionID
        XCTAssertNotEqual(newSessionId, currentSessionId)
    }

    // MARK: - configurePeerConnections

    func test_configurePeerConnections_withSFU_shouldSetupPeerConnections() async throws {
        let sfuStack = MockSFUStack()
        await subject.set(sfuAdapter: sfuStack.adapter)
        let videoFilter = VideoFilter(
            id: .unique,
            name: .unique,
            filter: { _ in fatalError() }
        )
        await subject.set(videoFilter: videoFilter)
        let ownCapabilities = Set([OwnCapability.blockUsers, .changeMaxDuration])
        await subject.set(ownCapabilities: ownCapabilities)
        let callSettings = CallSettings(cameraPosition: .back)
        await subject.enqueueCallSettings { _ in callSettings }
        await fulfillment {
            let currentValue = await self.subject.callSettings
            return currentValue == callSettings
        }

        try await subject.configurePeerConnections()

        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        let mockSubscriber = try await XCTAsyncUnwrap(await subject.subscriber as? MockRTCPeerConnectionCoordinator)

        await fulfillment {
            mockPublisher.timesCalled(.setUp) == 1
                && mockSubscriber.timesCalled(.setUp) == 1
        }
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(
                (CallSettings, [OwnCapability]).self,
                for: .setUp
            )?.first?.0,
            callSettings
        )
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(
                (CallSettings, [OwnCapability]).self,
                for: .setUp
            )?.first?.1.sorted(),
            Array(ownCapabilities).sorted()
        )
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.first?.id,
            videoFilter.id
        )
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.first?.name,
            videoFilter.name
        )

        XCTAssertEqual(
            mockSubscriber.recordedInputPayload(
                (CallSettings, [OwnCapability]).self,
                for: .setUp
            )?.first?.0,
            callSettings
        )
        XCTAssertEqual(
            mockSubscriber.recordedInputPayload(
                (CallSettings, [OwnCapability]).self,
                for: .setUp
            )?.first?.1.sorted(),
            Array(ownCapabilities).sorted()
        )
    }

    func test_configurePeerConnections_withSFU_completesSetUp() async throws {
        let sfuStack = MockSFUStack()
        await subject.set(sfuAdapter: sfuStack.adapter)
        let videoFilter = VideoFilter(
            id: .unique,
            name: .unique,
            filter: { _ in fatalError() }
        )
        await subject.set(videoFilter: videoFilter)
        let ownCapabilities = Set([OwnCapability.blockUsers, .changeMaxDuration])
        await subject.set(ownCapabilities: ownCapabilities)
        let callSettings = CallSettings(cameraPosition: .back)
        await subject.enqueueCallSettings { _ in callSettings }

        try await subject.configurePeerConnections()

        await fulfillment { await self.subject.publisher != nil }

        let _publisher = await subject.publisher
        let publisher = try XCTUnwrap(_publisher)
        let _subscriber = await subject.subscriber
        let subscriber = try XCTUnwrap(_subscriber)

        _ = await Task(timeoutInSeconds: 1) {
            try await publisher.ensureSetUpHasBeenCompleted()
        }.result

        _ = await Task(timeoutInSeconds: 1) {
            try await subscriber.ensureSetUpHasBeenCompleted()
        }.result
    }

    func test_configurePeerConnections_withActiveSession_shouldBeginScreenSharing() async throws {
        let sfuStack = MockSFUStack()
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        await subject.set(sfuAdapter: sfuStack.adapter)
        let screenShareSessionProvider = await subject.screenShareSessionProvider
        screenShareSessionProvider.activeSession = .init(
            localTrack: await subject.peerConnectionFactory.mockVideoTrack(forScreenShare: true),
            screenSharingType: .inApp,
            capturer: MockStreamVideoCapturer(),
            includeAudio: true
        )
        let ownCapabilities = Set<OwnCapability>([OwnCapability.blockUsers])
        await subject.set(ownCapabilities: ownCapabilities)

        try await subject.configurePeerConnections()
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)

        XCTAssertEqual(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first?.0,
            .inApp
        )
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first?.1,
            [.blockUsers]
        )
        XCTAssertTrue(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first?.2 ?? false
        )
    }

    func test_configurePeerConnections_withoutActiveSession_shouldNotBeginScreenSharing() async throws {
        let sfuStack = MockSFUStack()
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        await subject.set(sfuAdapter: sfuStack.adapter)
        let ownCapabilities = Set<OwnCapability>([OwnCapability.blockUsers])
        await subject.set(ownCapabilities: ownCapabilities)

        try await subject.configurePeerConnections()
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)

        XCTAssertEqual(mockPublisher.timesCalled(.beginScreenSharing), 0)
    }

    // MARK: - configureAudioSession

    func test_configureAudioSession_audioSessionWasConfigured() async throws {
        let sfuStack = MockSFUStack()
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        let statsAdapter = WebRTCStatsAdapter(
            sessionID: .unique,
            unifiedSessionID: .unique,
            isTracingEnabled: true,
            trackStorage: await subject.trackStorage
        )
        await subject.set(statsAdapter: statsAdapter)
        let ownCapabilities = Set<OwnCapability>([OwnCapability.blockUsers])
        await subject.set(ownCapabilities: ownCapabilities)

        try await subject.configureAudioSession(source: .inApp)

        await assertTrueAsync(await subject.audioSession.delegate === subject)
        await assertTrueAsync(await subject.audioSession.statsAdapter === statsAdapter)
    }

    func test_configureAudioSession_dispatchesAudioStoreUpdates() async throws {
        try await subject.configureAudioSession(source: .inApp)

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            guard let module = state.audioDeviceModule else { return false }
            let factory = await self.subject.peerConnectionFactory
            let adapterModule = factory.audioDeviceModule
            return module === adapterModule
                && state.isRecording == adapterModule.isRecording
                && state.isMicrophoneMuted == adapterModule.isMicrophoneMuted
        }
    }

    // MARK: - cleanUp

    func test_cleanUp_shouldResetProperties() async throws {
        let sfuStack = MockSFUStack()
        try await prepare(sfuStack: sfuStack)
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        let mockSubscriber = try await XCTAsyncUnwrap(await subject.subscriber as? MockRTCPeerConnectionCoordinator)

        await subject.cleanUp()

        XCTAssertEqual(mockPublisher.timesCalled(.close), 1)
        XCTAssertEqual(mockSubscriber.timesCalled(.close), 1)
        XCTAssertEqual(sfuStack.webSocket.timesCalled(.disconnectAsync), 1)

        await fulfillment { await self.subject.publisher == nil }
        await assertNilAsync(await subject.publisher)
        await assertNilAsync(await subject.subscriber)
        await assertNilAsync(await subject.statsAdapter)
        await assertNilAsync(await subject.sfuAdapter)
        await assertEqualAsync(await subject.token, "")
        await assertEqualAsync(await subject.sessionID, "")
        await assertEqualAsync(await subject.ownCapabilities, [])
        await assertEqualAsync(await subject.participants, [:])
        await assertEqualAsync(await subject.participantsCount, 0)
        await assertEqualAsync(await subject.anonymousCount, 0)
        await assertEqualAsync(await subject.participantPins, [])
    }

    func test_cleanUp_shouldStopActiveCaptureSession() async throws {
        let mockVideoCapturer = MockStreamVideoCapturer()
        let videoCaptureSessionProvider = await subject.videoCaptureSessionProvider
        videoCaptureSessionProvider.activeSession = .init(
            position: .front,
            localTrack: PeerConnectionFactory.mock().mockVideoTrack(forScreenShare: false),
            capturer: mockVideoCapturer
        )

        await subject.cleanUp()

        await fulfillment { mockVideoCapturer.timesCalled(.stopCapture) > 0 }
    }

    func test_cleanUp_shouldStopActiveScreemShareSession() async throws {
        let mockVideoCapturer = MockStreamVideoCapturer()
        let screenShareSessionProvider = await subject.screenShareSessionProvider
        screenShareSessionProvider.activeSession = .init(
            localTrack: PeerConnectionFactory.mock().mockVideoTrack(forScreenShare: true),
            screenSharingType: .inApp,
            capturer: mockVideoCapturer,
            includeAudio: true
        )

        await subject.cleanUp()

        await fulfillment { mockVideoCapturer.timesCalled(.stopCapture) > 0 }
    }

    // MARK: - cleanUpForReconnection

    func test_cleanUpForReconnection_shouldResetPropertiesForReconnection() async throws {
        let sfuStack = MockSFUStack()
        let ownCapabilities = Set([OwnCapability.blockUsers])
        let pins = [PinInfo(isLocal: true, pinnedAt: .init())]
        let userId = String.unique
        let currentParticipant = await CallParticipant.dummy(id: subject.sessionID)
        let participants = [
            userId: CallParticipant.dummy(id: userId),
            currentParticipant.sessionId: currentParticipant
        ]
        try await prepare(
            sfuStack: sfuStack,
            ownCapabilities: ownCapabilities,
            participants: participants,
            participantPins: pins
        )
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        let mockSubscriber = try await XCTAsyncUnwrap(await subject.subscriber as? MockRTCPeerConnectionCoordinator)
        let sessionId = await subject.sessionID
        await subject.didAddTrack(
            .dummy(
                kind: .video,
                peerConnectionFactory: await subject.peerConnectionFactory
            ),
            type: .video,
            for: userId
        )
        await fulfillment { await self.subject.participants[userId]?.track != nil }
        await subject.cleanUpForReconnection()

        XCTAssertEqual(mockPublisher.timesCalled(.close), 0)
        XCTAssertEqual(mockSubscriber.timesCalled(.close), 0)
        XCTAssertEqual(sfuStack.webSocket.timesCalled(.disconnectAsync), 0)
        await assertNilAsync(await subject.publisher)
        await assertNilAsync(await subject.subscriber)
        await assertNilAsync(await subject.statsAdapter)
        await assertNilAsync(await subject.sfuAdapter)
        await assertEqualAsync(await subject.token, "")
        await assertEqualAsync(await subject.sessionID, sessionId)
        await assertEqualAsync(await subject.ownCapabilities, ownCapabilities)
        await assertEqualAsync(await subject.participants[userId]?.track, nil)
        await assertEqualAsync(await subject.participantsCount, 12)
        await assertEqualAsync(await subject.anonymousCount, 22)
        await assertEqualAsync(await subject.participantPins, pins)
    }

    func test_cleanUpForReconnection_setsInitialCallSettingsToCallSettings() async throws {
        let sfuStack = MockSFUStack()
        let ownCapabilities = Set([OwnCapability.blockUsers])
        let pins = [PinInfo(isLocal: true, pinnedAt: .init())]
        let userId = String.unique
        let currentParticipant = await CallParticipant.dummy(id: subject.sessionID)
        let participants = [
            userId: CallParticipant.dummy(id: userId),
            currentParticipant.sessionId: currentParticipant
        ]
        try await prepare(
            sfuStack: sfuStack,
            ownCapabilities: ownCapabilities,
            participants: participants,
            participantPins: pins
        )
        await subject.enqueueCallSettings { _ in .init(cameraPosition: .back) }

        await subject.cleanUpForReconnection()

        await assertEqualAsync(await subject.callSettings.cameraPosition, .back)
    }

    // MARK: - didAddTrack

    func test_didAddTrack_videoOfExistingParticipant_shouldAddTrack() async throws {
        let participant = CallParticipant.dummy()
        let track = await subject
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: false)
        await subject.enqueue { _ in [participant.sessionId: participant] }

        await subject.didAddTrack(
            track,
            type: .video,
            for: participant.sessionId
        )

        await fulfillment {
            await self
                .subject
                .participants[participant.sessionId]?
                .track?
                .trackId == track.trackId
        }
    }

    func test_didAddTrack_screenSharingOfExistingParticipant_shouldAddTrack() async throws {
        let participant = CallParticipant.dummy()
        let track = await subject
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: true)
        await subject.enqueue { _ in [participant.sessionId: participant] }

        await subject.didAddTrack(
            track,
            type: .screenshare,
            for: participant.sessionId
        )

        await fulfillment {
            await self
                .subject
                .participants[participant.sessionId]?
                .screenshareTrack?
                .trackId == track.trackId
        }
    }

    // MARK: - didRemoveTrack

    func test_didRemoveTrack_videoOfExistingParticipant_shouldRemoveTrack() async throws {
        let participant = CallParticipant.dummy()
        let track = await subject
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: false)
        await subject.enqueue { _ in [participant.sessionId: participant] }
        await subject.didAddTrack(track, type: .video, for: participant.sessionId)

        await subject.didRemoveTrack(
            for: participant.sessionId
        )

        await fulfillment {
            await self
                .subject
                .participants[participant.sessionId]?
                .track?
                .trackId == nil
        }
    }

    func test_didRemoveTrack_screenSharingOfExistingParticipant_shouldRemoveTrack() async throws {
        let participant = CallParticipant.dummy()
        let track = await subject
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: true)
        await subject.enqueue { _ in [participant.sessionId: participant] }
        await subject.didAddTrack(track, type: .screenshare, for: participant.sessionId)

        await subject.didRemoveTrack(
            for: participant.sessionId
        )

        await fulfillment {
            await self
                .subject
                .participants[participant.sessionId]?
                .screenshareTrack?
                .trackId == nil
        }
    }

    // MARK: - trackFor

    func test_trackFor_withVideo_shouldReturnCorrectTrack() async throws {
        let participant = CallParticipant.dummy()
        let track = await subject
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: false)
        await subject.enqueue { _ in [participant.sessionId: participant] }
        await subject.didAddTrack(track, type: .video, for: participant.sessionId)

        let actual = await subject.track(for: participant.sessionId, of: .video)

        XCTAssertEqual(track.trackId, actual?.trackId)
    }

    func test_trackFor_withScreenShare_shouldReturnCorrectTrack() async throws {
        let participant = CallParticipant.dummy()
        let track = await subject
            .peerConnectionFactory
            .mockVideoTrack(forScreenShare: true)
        await subject.enqueue { _ in [participant.sessionId: participant] }
        await subject.didAddTrack(track, type: .screenshare, for: participant.sessionId)

        let actual = await subject.track(for: participant.sessionId, of: .screenshare)

        XCTAssertEqual(track.trackId, actual?.trackId)
    }

    // MARK: - didUpdateVideoOptions

    func test_didUpdateVideoOptions_shouldUpdateVideoOptions() async throws {
        let sfuStack = MockSFUStack()
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        await subject.set(sfuAdapter: sfuStack.adapter)
        try await subject.configurePeerConnections()
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        let mockSubscriber = try await XCTAsyncUnwrap(await subject.subscriber as? MockRTCPeerConnectionCoordinator)
        let newVideoOptions = VideoOptions(
            preferredCameraPosition: .back
        )

        await subject.set(videoOptions: newVideoOptions)

        XCTAssertEqual(mockPublisher.videoOptions.preferredCameraPosition, .back)
        XCTAssertEqual(mockSubscriber.videoOptions.preferredCameraPosition, .back)
    }

    // MARK: - didUpdateParticipants

    func test_didUpdateParticipants_shouldAssignTracksToParticipants() async throws {
        let initialParticipants: [String: CallParticipant] = [
            "1": .dummy(id: "1"),
            "2": .dummy(id: "2"),
            "3": .dummy(id: "3")
        ]
        let participantTracks: [String: RTCMediaStreamTrack] = [
            "1": await subject.peerConnectionFactory.mockAudioTrack(),
            "2": await subject.peerConnectionFactory.mockVideoTrack(forScreenShare: false),
            "3": await subject.peerConnectionFactory.mockVideoTrack(forScreenShare: true)
        ]
        await subject.enqueue { _ in initialParticipants }

        await subject.didAddTrack(participantTracks["2"]!, type: .video, for: "2")
        await subject.didAddTrack(participantTracks["3"]!, type: .screenshare, for: "3")

        await subject.enqueue { _ in initialParticipants }

        await fulfillment {
            let participant2 = await self.subject.participants["2"]
            let participant3 = await self.subject.participants["3"]

            return participant2?.track?.trackId == participantTracks["2"]?.trackId
                && participant3?.screenshareTrack?.trackId == participantTracks["3"]?.trackId
        }
    }

    func test_didUpdateParticipants_withIncomingVideoQualitySettings_shouldAssignTracksToParticipantsCorrectly() async throws {
        let initialParticipants: [String: CallParticipant] = [
            "1": .dummy(id: "1"),
            "2": .dummy(id: "2"),
            "3": .dummy(id: "3")
        ]
        let participantTracks: [String: RTCMediaStreamTrack] = [
            "1": await subject.peerConnectionFactory.mockAudioTrack(),
            "2": await subject.peerConnectionFactory.mockVideoTrack(forScreenShare: false),
            "3": await subject.peerConnectionFactory.mockVideoTrack(forScreenShare: true)
        ]
        await subject.set(incomingVideoQualitySettings: .disabled(group: .custom(sessionIds: ["2"])))
        await subject.enqueue { _ in initialParticipants }

        await subject.didAddTrack(participantTracks["2"]!, type: .video, for: "2")
        await subject.didAddTrack(participantTracks["3"]!, type: .screenshare, for: "3")

        await subject.enqueue { _ in initialParticipants }

        await fulfillment {
            let participant2 = await self.subject.participants["2"]
            let participant3 = await self.subject.participants["3"]

            return participant2?.track == nil
                && participant3?.screenshareTrack?.trackId == participantTracks["3"]?.trackId
        }
    }

    // MARK: - audioSessionDidUpdateCallSettings

    func test_audioSessionDidUpdateCallSettings_updatesCallSettingsAsExpected() async {
        let initialCallSettings = CallSettings(
            audioOn: false,
            videoOn: false,
            speakerOn: false,
            audioOutputOn: false,
            cameraPosition: .back
        )
        await subject.enqueueCallSettings { _ in initialCallSettings }
        await fulfillment {
            let currentValue = await self.subject.callSettings
            return currentValue == initialCallSettings
        }

        subject.audioSessionAdapterDidUpdateSpeakerOn(
            true,
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { await self.subject.callSettings.speakerOn }
    }

    // MARK: - updateCallSettings

    func test_updateCallSettings_noChanges_callSettingsDoNotChange() async {
        let sessionID = await subject.sessionID
        await subject.enqueueCallSettings { _ in .init(audioOn: true, videoOn: true) }
        var event = Stream_Video_Sfu_Event_TrackUnpublished()
        event.participant = Stream_Video_Sfu_Models_Participant()
        event.participant.sessionID = sessionID
        event.type = .screenShare

        await subject.updateCallSettings(from: event)

        await assertTrueAsync(await subject.callSettings.audioOn)
        await assertTrueAsync(await subject.callSettings.videoOn)
    }

    func test_updateCallSettings_withChangesInAudio_callSettingsDidUpdate() async {
        let sessionID = await subject.sessionID
        await subject.enqueueCallSettings { _ in .init(audioOn: true, videoOn: true) }
        var event = Stream_Video_Sfu_Event_TrackUnpublished()
        event.participant = Stream_Video_Sfu_Models_Participant()
        event.participant.sessionID = sessionID
        event.type = .audio

        await subject.updateCallSettings(from: event)

        await fulfillment {
            let currentValue = await self.subject.callSettings
            return currentValue.audioOn == false && currentValue.videoOn == true
        }
    }

    func test_updateCallSettings_withChangesInVideo_callSettingsDidUpdate() async {
        let sessionID = await subject.sessionID
        await subject.enqueueCallSettings { _ in .init(audioOn: true, videoOn: true) }
        var event = Stream_Video_Sfu_Event_TrackUnpublished()
        event.participant = Stream_Video_Sfu_Models_Participant()
        event.participant.sessionID = sessionID
        event.type = .video

        await subject.updateCallSettings(from: event)

        await fulfillment {
            let currentValue = await self.subject.callSettings
            return currentValue.audioOn == true && currentValue.videoOn == false
        }
    }

    // MARK: - enqueueCallSettings

    func test_enqueueCallSettings_withChanges_publisherWasUpdated() async throws {
        let sfuStack = MockSFUStack()
        await subject.set(sfuAdapter: sfuStack.adapter)
        try await subject.configurePeerConnections()

        let newCallSettings = CallSettings(
            audioOn: false,
            videoOn: true,
            speakerOn: false,
            audioOutputOn: true,
            cameraPosition: .back
        )

        await subject.enqueueCallSettings { _ in newCallSettings }
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)

        await fulfillment {
            mockPublisher.timesCalled(.didUpdateCallSettings) == 1
        }

        let updatedCallSettings = try XCTUnwrap(
            mockPublisher.recordedInputPayload(CallSettings.self, for: .didUpdateCallSettings)?
                .first
        )
        XCTAssertEqual(updatedCallSettings, newCallSettings)
    }

    // MARK: - permissionsAdapter(_:audioOn:)

    func test_permissionsAdapter_audioOn_valueWasUpdated_publisherWasUpdated() async throws {
        let sfuStack = MockSFUStack()
        await subject.set(sfuAdapter: sfuStack.adapter)
        try await subject.configurePeerConnections()
        await subject.enqueueCallSettings { _ in CallSettings(audioOn: false) }

        subject.permissionsAdapter(.init(subject), audioOn: true)

        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        await fulfillment {
            mockPublisher.timesCalled(.didUpdateCallSettings) == 2
        }

        let updatedAudioOn = try XCTUnwrap(
            mockPublisher.recordedInputPayload(CallSettings.self, for: .didUpdateCallSettings)?
                .last?.audioOn
        )
        XCTAssertTrue(updatedAudioOn)
    }

    // MARK: - permissionsAdapter(_:videoOn:)

    func test_permissionsAdapter_videoOn_valueWasUpdated_publisherWasUpdated() async throws {
        let sfuStack = MockSFUStack()
        await subject.set(sfuAdapter: sfuStack.adapter)
        try await subject.configurePeerConnections()
        await subject.enqueueCallSettings { _ in CallSettings(videoOn: false) }

        subject.permissionsAdapter(.init(subject), videoOn: true)

        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        await fulfillment {
            mockPublisher.timesCalled(.didUpdateCallSettings) == 2
        }

        let updatedVideoOn = try XCTUnwrap(
            mockPublisher.recordedInputPayload(CallSettings.self, for: .didUpdateCallSettings)?
                .last?.videoOn
        )
        XCTAssertTrue(updatedVideoOn)
    }

    // MARK: - Private helpers

    private func assertNilAsync<T>(
        _ expression: @autoclosure () async throws -> T?,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        XCTAssertNil(value, file: file, line: line)
    }

    private func assertEqualAsync<T: Equatable>(
        _ expression: @autoclosure () async throws -> T,
        _ expected: @autoclosure () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        let expectedValue = try await expected()
        XCTAssertEqual(value, expectedValue, file: file, line: line)
    }

    private func assertTrueAsync(
        _ expression: @autoclosure () async throws -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        XCTAssertTrue(value, file: file, line: line)
    }

    private func assertFalseAsync(
        _ expression: @autoclosure () async throws -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        XCTAssertFalse(value, file: file, line: line)
    }

    private func prepare(
        sfuStack: MockSFUStack = .init(),
        ownCapabilities: Set<OwnCapability> = [.changeMaxDuration],
        participants: [String: CallParticipant] = [.unique: .dummy()],
        participantPins: [PinInfo] = [.init(isLocal: true, pinnedAt: .init())]
    ) async throws {
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        let callSettings = CallSettings(cameraPosition: .back)
        let videoFilter = VideoFilter(
            id: .unique,
            name: .unique,
            filter: { _ in fatalError() }
        )
        await fulfillment { await self.subject.sessionID.isEmpty == false }
        await subject.set(sfuAdapter: sfuStack.adapter)
        await subject.set(videoFilter: videoFilter)
        await subject.set(ownCapabilities: ownCapabilities)
        await subject.enqueueCallSettings { _ in callSettings }
        await subject.set(token: .unique)
        await subject.set(participantsCount: 12)
        await subject.set(anonymousCount: 22)
        await subject.set(participantPins: participantPins)
        await subject.enqueue { _ in participants }
        try await subject.configurePeerConnections()

        let statsAdapter = WebRTCStatsAdapter(
            sessionID: .unique,
            unifiedSessionID: .unique,
            isTracingEnabled: true,
            trackStorage: await subject.trackStorage
        )
        await subject.set(statsAdapter: statsAdapter)
    }
}

#if compiler(>=6.0)
extension OwnCapability: @retroactive Comparable {
    public static func < (
        lhs: OwnCapability,
        rhs: OwnCapability
    ) -> Bool {
        lhs.rawValue <= rhs.rawValue
    }
}
#else
extension OwnCapability: Comparable {
    public static func < (
        lhs: OwnCapability,
        rhs: OwnCapability
    ) -> Bool {
        lhs.rawValue <= rhs.rawValue
    }
}
#endif
