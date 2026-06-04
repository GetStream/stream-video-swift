//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockWebRTCCoordinatorFactory: WebRTCCoordinatorProviding, @unchecked Sendable {

    var mockCoordinatorStack: MockWebRTCCoordinatorStack

    init(videoConfig: VideoConfig) {
        mockCoordinatorStack = .init(videoConfig: videoConfig)
    }

    private(set) var buildCoordinatorWasCalled: (
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        clientEventReporter: ClientEventReporting,
        callAuthentication: WebRTCCoordinator.AuthenticationHandler
    )?

    func buildCoordinator(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        clientEventReporter: ClientEventReporting,
        callAuthentication: @escaping WebRTCCoordinator.AuthenticationHandler
    ) -> WebRTCCoordinator {
        buildCoordinatorWasCalled = (
            user,
            apiKey,
            callCid,
            videoConfig,
            callSettings,
            clientEventReporter,
            callAuthentication
        )
        mockCoordinatorStack.callAuthenticator.authenticateHandler = callAuthentication
        return mockCoordinatorStack.coordinator
    }
}
