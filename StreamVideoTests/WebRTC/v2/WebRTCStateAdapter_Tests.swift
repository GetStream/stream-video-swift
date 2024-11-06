//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class WebRTCStateAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var user: User! = .dummy()
    private lazy var apiKey: String! = .unique
    private lazy var callCid: String! = .unique
    private lazy var videoConfig: VideoConfig! = .dummy()
    private lazy var rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory! = .init()
    private lazy var screenShareSessionProvider: ScreenShareSessionProvider! = .init()
    private lazy var subject: WebRTCStateAdapter! = .init(
        user: user,
        apiKey: apiKey,
        callCid: callCid,
        videoConfig: videoConfig,
        rtcPeerConnectionCoordinatorFactory: rtcPeerConnectionCoordinatorFactory,
        screenShareSessionProvider: screenShareSessionProvider
    )

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        screenShareSessionProvider = nil
        rtcPeerConnectionCoordinatorFactory = nil
        videoConfig = nil
        callCid = nil
        apiKey = nil
        user = nil
        super.tearDown()
    }

    // MARK: - audioSession

    func test_audioSession_delegateWasSetAsExpected() async throws {
        await assertTrueAsync(await subject.audioSession.delegate === subject)
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

    // MARK: - setCallSettings

    func test_setCallSettings_shouldUpdateCallSettings() async throws {
        let expected = CallSettings(cameraPosition: .back)

        await subject.set(callSettings: expected)

        await assertEqualAsync(await subject.callSettings, expected)
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
            preferredTargetResolution: .dummy(bitrate: 10000, height: 200, width: 300),
            preferredFormat: nil,
            preferredFps: 109_999
        )

        await subject.set(videoOptions: expected)

        await assertEqualAsync(await subject.videoOptions.preferredDimensions.width, expected.preferredDimensions.width)
        await assertEqualAsync(await subject.videoOptions.preferredDimensions.height, expected.preferredDimensions.height)
        await assertEqualAsync(await subject.videoOptions.preferredFps, expected.preferredFps)
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

    // MARK: - setStatsReporter

    func test_setStatsReporter_shouldUpdateStatsReporter() async throws {
        let expected = WebRTCStatsReporter(sessionID: .unique)

        await subject.set(statsReporter: expected)

        await assertTrueAsync(await subject.statsReporter === expected)
    }

    // MARK: - setSFUAdapter

    func test_setSFUAdapter_shouldUpdateSFUAdapterAndStatsReporter() async throws {
        let statsReporter = WebRTCStatsReporter(sessionID: .unique)
        await subject.set(statsReporter: statsReporter)
        let mockSFUStack = MockSFUStack()

        await subject.set(sfuAdapter: mockSFUStack.adapter)

        await assertTrueAsync(await subject.sfuAdapter === mockSFUStack.adapter)
        XCTAssertTrue(statsReporter.sfuAdapter === mockSFUStack.adapter)
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
        await subject.set(callSettings: callSettings)

        try await subject.configurePeerConnections()

        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        let mockSubscriber = try await XCTAsyncUnwrap(await subject.subscriber as? MockRTCPeerConnectionCoordinator)

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
        await assertNilAsync(await subject.statsReporter)
        await assertNilAsync(await subject.sfuAdapter)
        await assertEqualAsync(await subject.token, "")
        await assertEqualAsync(await subject.sessionID, "")
        await assertEqualAsync(await subject.ownCapabilities, [])
        await assertEqualAsync(await subject.participants, [:])
        await assertEqualAsync(await subject.participantsCount, 0)
        await assertEqualAsync(await subject.anonymousCount, 0)
        await assertEqualAsync(await subject.participantPins, [])
    }

    // MARK: - cleanUpForReconnection

    func test_cleanUpForReconnection_shouldResetPropertiesForReconnection() async throws {
        let sfuStack = MockSFUStack()
        let ownCapabilities = Set([OwnCapability.blockUsers])
        let pins = [PinInfo(isLocal: true, pinnedAt: .init())]
        let userId = String.unique
        let participants = [userId: CallParticipant.dummy(id: userId)]
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
        await assertNilAsync(await subject.statsReporter)
        await assertNilAsync(await subject.sfuAdapter)
        await assertEqualAsync(await subject.token, "")
        await assertEqualAsync(await subject.sessionID, sessionId)
        await assertEqualAsync(await subject.ownCapabilities, ownCapabilities)
        await assertEqualAsync(await subject.participants[userId]?.track, nil)
        await assertEqualAsync(await subject.participantsCount, 12)
        await assertEqualAsync(await subject.anonymousCount, 22)
        await assertEqualAsync(await subject.participantPins, pins)
    }

    // MARK: - restoreScreenSharing

    func test_restoreScreenSharing_withActiveSession_shouldBeginScreenSharing() async throws {
        let sfuStack = MockSFUStack()
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        await subject.set(sfuAdapter: sfuStack.adapter)
        try await subject.configurePeerConnections()
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        screenShareSessionProvider.activeSession = .init(
            localTrack: await subject.peerConnectionFactory.mockVideoTrack(forScreenShare: true),
            screenSharingType: .inApp,
            capturer: MockVideoCapturer()
        )
        let ownCapabilities = Set<OwnCapability>([OwnCapability.blockUsers])
        await subject.set(ownCapabilities: ownCapabilities)

        try await subject.restoreScreenSharing()

        XCTAssertEqual(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability]).self,
                for: .beginScreenSharing
            )?.first?.0,
            .inApp
        )
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability]).self,
                for: .beginScreenSharing
            )?.first?.1,
            [.blockUsers]
        )
    }

    func test_restoreScreenSharing_withoutActiveSession_shouldNotBeginScreenSharing() async throws {
        let sfuStack = MockSFUStack()
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        await subject.set(sfuAdapter: sfuStack.adapter)
        try await subject.configurePeerConnections()
        let mockPublisher = try await XCTAsyncUnwrap(await subject.publisher as? MockRTCPeerConnectionCoordinator)
        let ownCapabilities = Set<OwnCapability>([OwnCapability.blockUsers])
        await subject.set(ownCapabilities: ownCapabilities)

        try await subject.restoreScreenSharing()

        XCTAssertEqual(mockPublisher.timesCalled(.beginScreenSharing), 0)
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
            preferredTargetResolution: .dummy(),
            preferredFormat: nil,
            preferredFps: 17
        )

        await subject.set(videoOptions: newVideoOptions)

        XCTAssertEqual(mockPublisher.videoOptions.preferredFps, 17)
        XCTAssertEqual(mockSubscriber.videoOptions.preferredFps, 17)
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
        let updatedCallSettings = CallSettings(
            audioOn: false,
            videoOn: false,
            speakerOn: true,
            audioOutputOn: false,
            cameraPosition: .back
        )

        subject.audioSessionAdapterDidUpdateCallSettings(
            await subject.audioSession,
            callSettings: updatedCallSettings
        )

        await fulfillment { [subject] in
            await subject?.callSettings == updatedCallSettings
        }
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
        await subject.set(callSettings: callSettings)
        await subject.set(token: .unique)
        await subject.set(participantsCount: 12)
        await subject.set(anonymousCount: 22)
        await subject.set(participantPins: participantPins)
        await subject.enqueue { _ in participants }
        try await subject.configurePeerConnections()
        await subject.set(statsReporter: WebRTCStatsReporter(sessionID: .unique))
    }
}

extension OwnCapability: Comparable {
    public static func < (
        lhs: OwnCapability,
        rhs: OwnCapability
    ) -> Bool {
        lhs.rawValue <= rhs.rawValue
    }
}
