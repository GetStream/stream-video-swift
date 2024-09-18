//
//  MockWebRTCCoordinatorFactory.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 18/9/24.
//

@testable import StreamVideo

final class MockWebRTCCoordinatorFactory: WebRTCCoordinatorProviding, @unchecked Sendable {

    var mockCoordinatorStack: MockWebRTCCoordinatorStack = .init()

    private var buildCoordinatorWasCalled: (
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        callAuthentication: WebRTCCoordinator.AuthenticationHandler
    )?

    func buildCoordinator(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        callAuthentication: @escaping WebRTCCoordinator.AuthenticationHandler
    ) -> WebRTCCoordinator {
        buildCoordinatorWasCalled = (user, apiKey, callCid, videoConfig, callAuthentication)
        return mockCoordinatorStack.coordinator
    }
}
