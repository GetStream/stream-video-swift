//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallKitAdapterTests: XCTestCase, @unchecked Sendable {

    private lazy var callKitPushNotificationAdapter: MockCallKitPushNotificationAdapter! = .init()
    private lazy var callKitService: MockCallKitService! = .init()
    private lazy var subject: CallKitAdapter! = .init()

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        InjectedValues[\.callKitPushNotificationAdapter] = callKitPushNotificationAdapter
        InjectedValues[\.callKitService] = callKitService
        CurrentDevice.currentValue.didUpdate(.phone)
    }

    override func tearDown() {
        callKitPushNotificationAdapter = nil
        callKitService = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - registerForIncomingCalls

    func test_registerForIncomingCalls_callKitPushNotificationAdapterWasCalled() {
        // When
        subject.registerForIncomingCalls()

        // Then
        XCTAssertTrue(callKitPushNotificationAdapter.registerWasCalled)
    }

    // MARK: - unregisterForIncomingCalls

    func test_unregisterForIncomingCalls_callKitPushNotificationAdapterWasCalled() {
        // When
        subject.unregisterForIncomingCalls()

        // Then
        XCTAssertTrue(callKitPushNotificationAdapter.unregisterWasCalled)
    }

    // MARK: - streamVideo updated

    func testDidUpdate_streamVideoIsNotNilAndNotConnected_callKitServiceWasUpdatedAndRegisterWasCalled() async throws {
        // Given
        let streamVideo = try await makeStreamVideo()

        // When
        subject.streamVideo = streamVideo

        // Then
        XCTAssertTrue(callKitService.streamVideo === streamVideo)
        XCTAssertTrue(callKitPushNotificationAdapter.registerWasCalled)
    }

    func testDidUpdate_StreamVideoNil_callKitServiceWasUpdatedAndUnregisterWasCalled() {
        // When
        subject.streamVideo = nil

        // Then
        XCTAssertNil(callKitService.streamVideo)
        XCTAssertTrue(callKitPushNotificationAdapter.unregisterWasCalled)
    }

    // MARK: - callSettings updated

    func test_callSettings_callKitServiceReceivedTheUpdatedValue() {
        let callSettings = CallSettings(audioOn: false, videoOn: true)

        subject.callSettings = callSettings

        XCTAssertEqual(callKitService.callSettings, callSettings)
    }

    // MARK: - Private Helpers

    private func makeStreamVideo() async throws -> StreamVideo {
        let userId = "test_user"

        let authenticationProvider = TestsAuthenticationProvider()
        let tokenResponse = try await authenticationProvider.authenticate(
            environment: "demo",
            baseURL: .init(string: "https://pronto.getstream.io/api/auth/create-token")!,
            userId: userId
        )
        
        let client = StreamVideo(
            apiKey: tokenResponse.apiKey,
            user: User(id: userId),
            token: .init(rawValue: tokenResponse.token),
            videoConfig: .dummy()
        )

        return client
    }
}
