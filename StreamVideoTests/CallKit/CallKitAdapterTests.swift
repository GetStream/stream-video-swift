//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallKitAdapterTests: XCTestCase {

    private lazy var callKitPushNotificationAdapter: MockCallKitPushNotificationAdapter! = .init()
    private lazy var callKitService: MockCallKitService! = .init()
    private lazy var subject: CallKitAdapter! = .init()

    override func setUp() {
        super.setUp()
        InjectedValues[\.callKitPushNotificationAdapter] = callKitPushNotificationAdapter
        InjectedValues[\.callKitService] = callKitService
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

    func testDidUpdate_streamVideoIsNotNilAndNotConnected_callKitServiceWasUpdatedAndRegisterWasNotCalled() async throws {
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
            token: .init(rawValue: tokenResponse.token)
        )

        return client
    }
}
