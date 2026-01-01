//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockWebRTCCoordinatorFactory: WebRTCCoordinatorProviding, @unchecked Sendable {

    var mockCoordinatorStack: MockWebRTCCoordinatorStack

    init(videoConfig: VideoConfig) {
        mockCoordinatorStack = .init(videoConfig: videoConfig)
    }

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
