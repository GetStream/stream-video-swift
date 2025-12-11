//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
            create: create,
            ring: ring,
            notify: notify,
            options: options
        )

        let input = try XCTUnwrap(mockCoordinatorStack.callAuthenticator.authenticateCalledWithInput.first)
        XCTAssertTrue(input.create)
        XCTAssertTrue(input.ring)
        XCTAssertTrue(input.notify)
        XCTAssertEqual(input.options?.team, options.team)
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
            create: create,
            ring: ring,
            notify: notify,
            options: options
        )

        XCTAssertEqual(response, expected)
        XCTAssertEqual(sfuAdapter.hostname, "getstream.io")
        XCTAssertEqual(sfuAdapter.connectURL.absoluteString, "wss://getstream.io")
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
            create: create,
            ring: ring,
            notify: notify,
            options: options
        )

        XCTAssertEqual(response, expected)
        XCTAssertEqual(sfuAdapter.hostname, "getstream.io")
        XCTAssertEqual(sfuAdapter.connectURL.absoluteString, "wss://getstream.io")
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
            create: create,
            ring: ring,
            notify: notify,
            options: options
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
            create: create,
            ring: ring,
            notify: notify,
            options: options
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
            create: create,
            ring: ring,
            notify: notify,
            options: options
        )

        let callSettings = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .callSettings
        XCTAssertEqual(callSettings, expected, file: file, line: line)
    }
}
