//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCAuthenticator_Tests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var subject: WebRTCAuthenticator! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        _ = mockPermissions
    }

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        mockPermissions.dismantle()
        mockCoordinatorStack = nil
        mockPermissions = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - authenticate

    func test_authenticate_cancelledBeforeResponseReturns_doesNotApplyResponse() async throws {
        let coordinator = mockCoordinatorStack.coordinator
        await coordinator.stateAdapter.set(token: "existing-token")
        mockCoordinatorStack.callAuthenticator.authenticateHandler = { _, _, _, _, _, _, _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return .dummy()
        }
        let subject = try XCTUnwrap(subject)
        let operation = Task {
            try await subject.authenticate(
                coordinator: coordinator,
                currentSFU: nil,
                migratingFromList: nil,
                create: false,
                ring: false,
                notify: false,
                options: nil,
                declaresPlaybackCapabilities: false
            )
        }

        do {
            _ = try await operation.value
            XCTFail("Cancelled authentication applied a late response")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        let token = await coordinator.stateAdapter.token
        XCTAssertEqual(token, "existing-token")
        let statsAdapter = await coordinator.stateAdapter.statsAdapter
        XCTAssertNil(statsAdapter)
    }

    func test_authenticate_cancelledDuringCapabilitiesUpdate_doesNotRestoreCleanedState() async throws {
        let coordinator = mockCoordinatorStack.coordinator
        let stateAdapter = coordinator.stateAdapter
        await stateAdapter.set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        try await stateAdapter.configurePeerConnections()
        let publisher = try await XCTAsyncUnwrap(
            await stateAdapter.publisher as? MockRTCPeerConnectionCoordinator
        )
        let audioSettings = AudioSettings.dummy(micDefaultOn: true)
        await stateAdapter.set(audioSettings: audioSettings)
        let screenShareSessionProvider = await stateAdapter.screenShareSessionProvider
        screenShareSessionProvider.activeSession = .init(
            localTrack: await stateAdapter.peerConnectionFactory.mockVideoTrack(forScreenShare: true),
            screenSharingType: .inApp,
            capturer: MockStreamVideoCapturer(),
            includeAudio: false
        )
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummy(
                call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                ownCapabilities: [.sendAudio, .sendVideo]
            )
        )
        let leaveDuringUpdate: @Sendable () async -> Void = {
            withUnsafeCurrentTask { $0?.cancel() }
            await stateAdapter.cleanUp()
        }
        publisher.stub(for: .stopScreenSharing, with: leaveDuringUpdate)
        let subject = try XCTUnwrap(subject)
        let operation = Task {
            try await subject.authenticate(
                coordinator: coordinator,
                currentSFU: nil,
                migratingFromList: nil,
                create: false,
                ring: false,
                notify: false,
                options: nil,
                declaresPlaybackCapabilities: false
            )
        }

        do {
            _ = try await operation.value
            XCTFail("Cancelled authentication restored cleaned state")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertEqual(publisher.timesCalled(.stopScreenSharing), 1)
        let token = await stateAdapter.token
        let ownCapabilities = await stateAdapter.ownCapabilities
        let currentAudioSettings = await stateAdapter.audioSettings
        XCTAssertEqual(token, "")
        XCTAssertEqual(ownCapabilities, [])
        XCTAssertEqual(currentAudioSettings, audioSettings)
        let statsAdapter = await stateAdapter.statsAdapter
        XCTAssertNil(statsAdapter)
    }

    func test_authenticate_withValidData_callAuthenticationWasCalledWithExpectedInput() async throws {
        let currentSFU = String.unique
        let create = true
        let ring = true
        let notify = true
        let options = CreateCallOptions(team: .unique)
        let expected = JoinCallResponse.dummy()
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

        _ = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: currentSFU,
            migratingFromList: nil,
            create: create,
            ring: ring,
            notify: notify,
            options: options,
            declaresPlaybackCapabilities: false
        )

        let input = try XCTUnwrap(mockCoordinatorStack.callAuthenticator.authenticateCalledWithInput.first)
        XCTAssertTrue(input.create)
        XCTAssertTrue(input.ring)
        XCTAssertNil(input.migratingFromList)
        XCTAssertTrue(input.notify)
        XCTAssertEqual(input.options?.team, options.team)
    }

    func test_authenticate_withMigratingFromList_callAuthenticationWasCalledWithExpectedInput() async throws {
        let migratingFromList = [String.unique, String.unique]
        let expected = JoinCallResponse.dummy()
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

        _ = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: migratingFromList,
            create: false,
            ring: false,
            notify: false,
            options: nil,
            declaresPlaybackCapabilities: false
        )

        let input = try XCTUnwrap(mockCoordinatorStack.callAuthenticator.authenticateCalledWithInput.first)
        XCTAssertEqual(input.migratingFromList, migratingFromList)
    }

    func test_authenticate_declaringPlaybackCapabilities_callAuthenticationReceivesTheFlag() async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(.dummy())

        _ = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: nil,
            create: false,
            ring: false,
            notify: false,
            options: nil,
            declaresPlaybackCapabilities: true
        )

        let input = try XCTUnwrap(mockCoordinatorStack.callAuthenticator.authenticateCalledWithInput.first)
        XCTAssertTrue(input.declaresPlaybackCapabilities)
    }

    func test_authenticate_notDeclaringPlaybackCapabilities_callAuthenticationReceivesTheFlag() async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(.dummy())

        _ = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: nil,
            create: false,
            ring: false,
            notify: false,
            options: nil,
            declaresPlaybackCapabilities: false
        )

        let input = try XCTUnwrap(mockCoordinatorStack.callAuthenticator.authenticateCalledWithInput.first)
        XCTAssertFalse(input.declaresPlaybackCapabilities)
    }

    // MARK: - authenticate (HLS grant)

    func test_authenticate_hlsGrant_returnsResponseWithoutSFUAdapter() async throws {
        let expected = JoinCallResponse.dummyHLSGrant()
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

        let (sfuAdapter, response) = try await authenticate(declaresPlaybackCapabilities: true)

        XCTAssertNil(sfuAdapter)
        XCTAssertEqual(response, expected)
    }

    func test_authenticate_hlsGrant_appliesOwnCapabilities() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(ownCapabilities: [.sendAudio, .sendVideo])
        )

        _ = try await authenticate(declaresPlaybackCapabilities: true)

        let ownCapabilities = await stateAdapter.ownCapabilities
        XCTAssertEqual(ownCapabilities, [.sendAudio, .sendVideo])
    }

    func test_authenticate_hlsGrant_doesNotApplySFUStatsOrAudioState() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        let audioSettings = await stateAdapter.audioSettings
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(
                call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: true)))
            )
        )

        _ = try await authenticate(declaresPlaybackCapabilities: true)

        let token = await stateAdapter.token
        let currentAudioSettings = await stateAdapter.audioSettings
        let statsAdapter = await stateAdapter.statsAdapter
        XCTAssertEqual(token, "")
        XCTAssertEqual(currentAudioSettings, audioSettings)
        XCTAssertNil(statsAdapter)
    }

    func test_authenticate_hlsGrant_turnsAudioAndVideoOff() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(ownCapabilities: [.sendAudio, .sendVideo])
        )

        _ = try await authenticate(declaresPlaybackCapabilities: true)

        let callSettings = try await stateAdapter
            .$callSettings
            .filter { !$0.audioOn && !$0.videoOn }
            .nextValue(timeout: defaultTimeout)
        XCTAssertFalse(callSettings.audioOn)
        XCTAssertFalse(callSettings.videoOn)
    }

    func test_authenticate_hlsGrant_keepsTheOtherCallSettings() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        let initial = await stateAdapter.callSettings
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(ownCapabilities: [.sendAudio, .sendVideo])
        )

        _ = try await authenticate(declaresPlaybackCapabilities: true)

        let updated = try await stateAdapter
            .$callSettings
            .filter { !$0.audioOn && !$0.videoOn }
            .nextValue(timeout: defaultTimeout)
        XCTAssertEqual(updated.speakerOn, initial.speakerOn)
        XCTAssertEqual(updated.audioOutputOn, initial.audioOutputOn)
        XCTAssertEqual(updated.cameraPosition, initial.cameraPosition)
    }

    func test_authenticate_hlsGrantNotDeclared_throwsClientError() async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(ownCapabilities: [.sendAudio])
        )

        await assertAuthenticateThrowsClientError(
            declaresPlaybackCapabilities: false,
            containing: "not requested"
        )
    }

    func test_authenticate_hlsGrantWithHTTPPlaylistURL_throwsClientError() async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(
                ownCapabilities: [.sendAudio],
                playback: .dummy(playlistUrl: "http://example.com/live.m3u8")
            )
        )

        await assertAuthenticateThrowsClientError(containing: "playlist URL")
    }

    func test_authenticate_hlsGrantWithUnknownType_throwsClientError() async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(
                ownCapabilities: [.sendAudio],
                playback: .dummy(type: .unknown)
            )
        )

        await assertAuthenticateThrowsClientError(containing: "playback type")
    }

    func test_authenticate_hlsGrantWithEmptyPlaylistURL_throwsClientError() async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(
                ownCapabilities: [.sendAudio],
                playback: .dummy(playlistUrl: "")
            )
        )

        await assertAuthenticateThrowsClientError(containing: "playlist URL")
    }

    func test_authenticate_hlsGrantWithRelativePlaylistURL_throwsClientError() async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(
            .dummyHLSGrant(
                ownCapabilities: [.sendAudio],
                playback: .dummy(playlistUrl: "/live.m3u8")
            )
        )

        await assertAuthenticateThrowsClientError(containing: "playlist URL")
    }

    func test_authenticate_withValidData_shouldReturnSFUAdapterAndJoinCallResponse() async throws {
        let currentSFU = String.unique
        let create = true
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy()
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

        let (sfuAdapter, response) = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: currentSFU,
            migratingFromList: nil,
            create: create,
            ring: ring,
            notify: notify,
            options: options,
            declaresPlaybackCapabilities: false
        )

        XCTAssertEqual(response, expected)
        let unwrappedSFUAdapter = try XCTUnwrap(sfuAdapter)
        XCTAssertEqual(unwrappedSFUAdapter.hostname, "getstream.io")
        XCTAssertEqual(unwrappedSFUAdapter.connectURL.absoluteString, "wss://getstream.io")
    }

    func test_authenticate_withNilCurrentSFU_shouldStillReturnSFUAdapterAndJoinCallResponse() async throws {
        let create = true
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy()
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

        let (sfuAdapter, response) = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: nil,
            create: create,
            ring: ring,
            notify: notify,
            options: options,
            declaresPlaybackCapabilities: false
        )

        XCTAssertEqual(response, expected)
        let unwrappedSFUAdapter = try XCTUnwrap(sfuAdapter)
        XCTAssertEqual(unwrappedSFUAdapter.hostname, "getstream.io")
        XCTAssertEqual(unwrappedSFUAdapter.connectURL.absoluteString, "wss://getstream.io")
    }

    // MARK: with sendAudio and sendVideo capabilities

    func test_authenticate_withCreateTrueAndInitialCallSettings_withSendAudioAndVideoCapabilities_shouldSetInitialCallSettings(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: [.sendAudio, .sendVideo]
                )
            ),
            expected: CallSettings(audioOn: true, videoOn: true, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioAndVideoCapabilities_videoOnSpeakerFalse_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: [.sendAudio, .sendVideo]
                )
            ),
            expected: .init(audioOn: true, videoOn: true, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioAndVideoCapabilities_videoOffSpeakerTrue_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: true),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendAudio, .sendVideo]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioAndVideoCapabilities_videoOffSpeakerFalseDefaultDeviceSpeaker_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .speaker, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendAudio, .sendVideo]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioAndVideoCapabilities_videoOffSpeakerFalseDefaultDeviceNonSpeakershouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .earpiece, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendAudio, .sendVideo]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: false)
        )
    }

    func test_authenticate_withCreateFalseAndInitialCallSettings_withSendAudioAndVideoCapabilities_shouldSetInitialCallSettings(
    ) async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: [.sendAudio, .sendVideo]
                )
            ),
            expected: CallSettings(audioOn: true, videoOn: true, speakerOn: true)
        )
    }

    func test_authenticate_withCreateFalseWithoutInitialCallSettings_withSendAudioAndVideoCapabilities_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: [.sendAudio, .sendVideo]
                )
            ),
            expected: .init(audioOn: true, videoOn: true, speakerOn: true)
        )
    }

    // MARK: with sendAudio capability

    func test_authenticate_withCreateTrueAndInitialCallSettings_withSendAudioCapability_shouldSetInitialCallSettings() async throws {
        try await assertCallSettings(
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: [.sendAudio]
                )
            ),
            expected: CallSettings(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioCapability_videoOnSpeakerFalse_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: [.sendAudio]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioCapability_videoOffSpeakerTrue_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: true),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendAudio]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioCapability_videoOffSpeakerFalseDefaultDeviceSpeaker_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .speaker, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendAudio]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendAudioCapability_videoOffSpeakerFalseDefaultDeviceNonSpeakershouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .earpiece, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendAudio]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: false)
        )
    }

    func test_authenticate_withCreateFalseAndInitialCallSettings_withSendAudioCapability_shouldSetInitialCallSettings(
    ) async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: [.sendAudio]
                )
            ),
            expected: CallSettings(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateFalseWithoutInitialCallSettings_withSendAudioCapability_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: [.sendAudio]
                )
            ),
            expected: .init(audioOn: true, videoOn: false, speakerOn: true)
        )
    }

    // MARK: with sendVideo capability

    func test_authenticate_withCreateTrueAndInitialCallSettings_withSendVideoCapability_shouldSetInitialCallSettings() async throws {
        try await assertCallSettings(
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: [.sendVideo]
                )
            ),
            expected: CallSettings(audioOn: false, videoOn: true, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendVideoCapability_videoOnSpeakerFalse_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: [.sendVideo]
                )
            ),
            expected: .init(audioOn: false, videoOn: true, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendVideoCapability_videoOffSpeakerTrue_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: true),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendVideo]
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendVideoCapability_videoOffSpeakerFalseDefaultDeviceSpeaker_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .speaker, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendVideo]
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withSendVideoCapability_videoOffSpeakerFalseDefaultDeviceNonSpeakershouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .earpiece, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: [.sendVideo]
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: false)
        )
    }

    func test_authenticate_withCreateFalseAndInitialCallSettings_withSendVideoCapability_shouldSetInitialCallSettings(
    ) async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: [.sendVideo]
                )
            ),
            expected: CallSettings(audioOn: false, videoOn: true, speakerOn: true)
        )
    }

    func test_authenticate_withCreateFalseWithoutInitialCallSettings_withSendVideoCapability_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: [.sendVideo]
                )
            ),
            expected: .init(audioOn: false, videoOn: true, speakerOn: true)
        )
    }

    // MARK: without audio or video capabilities

    func test_authenticate_withCreateTrueAndInitialCallSettings_withoutCapabilities_shouldSetInitialCallSettings() async throws {
        try await assertCallSettings(
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: []
                )
            ),
            expected: CallSettings(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withoutCapabilities_videoOnSpeakerFalse_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: []
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withoutCapabilities_videoOffSpeakerTrue_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: true),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: []
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withoutCapabilities_videoOffSpeakerFalseDefaultDeviceSpeaker_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .speaker, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: []
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_withoutCapabilities_videoOffSpeakerFalseDefaultDeviceNonSpeakershouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:false we respect the value of speakerDefaultOn.
                            audio: .dummy(defaultDevice: .earpiece, micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: false)
                        )
                    ),
                    ownCapabilities: []
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: false)
        )
    }

    func test_authenticate_withCreateFalseAndInitialCallSettings_withoutCapabilities_shouldSetInitialCallSettings() async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: CallSettings(audioOn: true, videoOn: true, speakerOn: true),
            result: .success(
                .dummy(
                    call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))),
                    ownCapabilities: []
                )
            ),
            expected: CallSettings(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    func test_authenticate_withCreateFalseWithoutInitialCallSettings_withoutCapabilities_shouldSetCallSettingsFromResponse(
    ) async throws {
        try await assertCallSettings(
            create: false,
            initialCallSettings: nil,
            result: .success(
                .dummy(
                    call: .dummy(
                        settings: .dummy(
                            // Because videoOn:true speaker will default to true.
                            audio: .dummy(micDefaultOn: true, speakerDefaultOn: false),
                            video: .dummy(cameraDefaultOn: true)
                        )
                    ),
                    ownCapabilities: []
                )
            ),
            expected: .init(audioOn: false, videoOn: false, speakerOn: true)
        )
    }

    // MARK: -

    func test_authenticate_updatesVideoOptions() async throws {
        let create = false
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy(
            call: .dummy(
                settings: .dummy(
                    video: .dummy(
                        cameraFacing: .back,
                        targetResolution: .init(bitrate: 100, height: 200, width: 300)
                    )
                )
            )
        )
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

        _ = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: nil,
            create: create,
            ring: ring,
            notify: notify,
            options: options,
            declaresPlaybackCapabilities: false
        )

        let videoOptions = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .videoOptions
        XCTAssertEqual(videoOptions.preferredCameraPosition, .back)
    }

    func test_authenticate_updatesIntervalOnStatsReporter() async throws {
        let create = false
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy(
            statsOptions: .init(enableRtcStats: false, reportingIntervalMs: 12000)
        )
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

        _ = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: nil,
            create: create,
            ring: ring,
            notify: notify,
            options: options,
            declaresPlaybackCapabilities: false
        )

        let statsReporter = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .statsAdapter
        XCTAssertEqual(statsReporter?.deliveryInterval, 12)
    }

    // MARK: with only sendAudio capability

    // MARK: - waitForAuthentication

    func test_waitForAuthentication_shouldThrowErrorIfTimeout() async throws {
        _ = await XCTAssertThrowsErrorAsync {
            try await subject
                .waitForAuthentication(on: mockCoordinatorStack.sfuStack.adapter)
        }
    }

    func test_waitForAuthentication_shouldWaitUntilConnectionStateIsAuthenticating() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in

            group.addTask {
                try await self.subject
                    .waitForAuthentication(on: self.mockCoordinatorStack.sfuStack.adapter)
            }

            group.addTask {
                await self.wait(for: 0.5)
                self.mockCoordinatorStack
                    .sfuStack
                    .setConnectionState(to: .authenticating)
            }

            try await group.waitForAll()
        }
    }

    // MARK: - waitForConnect

    func test_waitForConnect_shouldThrowErrorIfTimeout() async throws {
        _ = await XCTAssertThrowsErrorAsync {
            try await subject
                .waitForConnect(on: mockCoordinatorStack.sfuStack.adapter)
        }
    }

    func test_waitForConnect_shouldWaitUntilConnectionStateIsConnected() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in

            group.addTask {
                try await self.subject
                    .waitForConnect(on: self.mockCoordinatorStack.sfuStack.adapter)
            }

            group.addTask {
                await self.wait(for: 0.5)
                self.mockCoordinatorStack
                    .sfuStack
                    .setConnectionState(to: .connected(healthCheckInfo: .init()))
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Private Helpers

    /// Authenticates with the shared coordinator and the given capability flag.
    private func authenticate(
        declaresPlaybackCapabilities: Bool
    ) async throws -> (sfuAdapter: SFUAdapter?, response: JoinCallResponse) {
        try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: nil,
            create: false,
            ring: false,
            notify: false,
            options: nil,
            declaresPlaybackCapabilities: declaresPlaybackCapabilities
        )
    }

    /// Asserts that a rejected grant fails with a ``ClientError`` before the
    /// response is applied to the state adapter.
    private func assertAuthenticateThrowsClientError(
        declaresPlaybackCapabilities: Bool = true,
        containing message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await authenticate(
                declaresPlaybackCapabilities: declaresPlaybackCapabilities
            )
            XCTFail("Expected authenticate to throw.", file: file, line: line)
        } catch {
            XCTAssertTrue(error is ClientError, file: file, line: line)
            XCTAssertTrue(
                error.localizedDescription.contains(message),
                "Unexpected error: \(error)",
                file: file,
                line: line
            )
        }
        let ownCapabilities = await mockCoordinatorStack.coordinator.stateAdapter.ownCapabilities
        XCTAssertTrue(ownCapabilities.isEmpty, file: file, line: line)
    }

    private func assertCallSettings(
        create: Bool = true,
        ring: Bool = true,
        notify: Bool = true,
        options: CreateCallOptions = .init(),
        initialCallSettings: CallSettings? = nil,
        result: Result<JoinCallResponse, Error>,
        expected: CallSettings,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        mockCoordinatorStack.callAuthenticator.authenticateResult = result

        if let initialCallSettings {
            await mockCoordinatorStack
                .coordinator
                .stateAdapter
                .set(initialCallSettings: initialCallSettings)
        }

        _ = try await subject.authenticate(
            coordinator: mockCoordinatorStack.coordinator,
            currentSFU: nil,
            migratingFromList: nil,
            create: create,
            ring: ring,
            notify: notify,
            options: options,
            declaresPlaybackCapabilities: false
        )

        await fulfillment(file: file, line: line) {
            let callSettings = await self.mockCoordinatorStack
                .coordinator
                .stateAdapter
                .callSettings
            return callSettings == expected
        }
    }
}
