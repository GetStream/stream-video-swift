//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        peerConnectionFactory: PeerConnectionFactory,
        callAuthentication: WebRTCCoordinator.AuthenticationHandler
    )?

    func buildCoordinator(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        peerConnectionFactory: PeerConnectionFactory,
        callAuthentication: @escaping WebRTCCoordinator.AuthenticationHandler
    ) -> WebRTCCoordinator {
        buildCoordinatorWasCalled = (user, apiKey, callCid, videoConfig, peerConnectionFactory, callAuthentication)
        return mockCoordinatorStack.coordinator
    }
}
