//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCAuthenticator_Tests: XCTestCase {

    private static var videoConfig: VideoConfig! = .dummy()

    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private lazy var subject: WebRTCAuthenticator! = .init()

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        mockCoordinatorStack = nil
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

    func test_authenticate_withCreateTrueAndInitialCallSettings_shouldSetInitialCallSettings() async throws {
        let create = true
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy(call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))))
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)
        let initialCallSettings = CallSettings(
            audioOn: true,
            videoOn: true,
            speakerOn: true
        )
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(initialCallSettings: initialCallSettings)

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
        XCTAssertEqual(callSettings, initialCallSettings)
    }

    func test_authenticate_withCreateTrueWithoutInitialCallSettings_shouldSetCallSettingsFromResponse() async throws {
        let create = true
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy(call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: true))))
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)

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
        XCTAssertEqual(callSettings, expected.call.settings.toCallSettings)
    }

    func test_authenticate_withCreateFalse_shouldNotSetInitialCallSettings() async throws {
        let create = false
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy(call: .dummy(settings: .dummy(audio: .dummy(micDefaultOn: false))))
        mockCoordinatorStack.callAuthenticator.authenticateResult = .success(expected)
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(initialCallSettings: .init(audioOn: false, audioOutputOn: false))

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
        XCTAssertTrue(callSettings.audioOn)
        XCTAssertTrue(callSettings.audioOutputOn)
    }

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
        XCTAssertEqual(videoOptions.preferredDimensions.height, 200)
        XCTAssertEqual(videoOptions.preferredDimensions.width, 300)
    }

    func test_authenticate_updatesIntervalOnStatsReporter() async throws {
        let create = false
        let ring = true
        let notify = true
        let options = CreateCallOptions()
        let expected = JoinCallResponse.dummy(
            statsOptions: .init(reportingIntervalMs: 12000)
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
            .statsReporter
        XCTAssertEqual(statsReporter?.interval, 12)
    }

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
}
