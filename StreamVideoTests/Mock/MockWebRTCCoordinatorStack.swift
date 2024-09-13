//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

final class MockWebRTCCoordinatorStack {

    let user: User
    let apiKey: String
    let callCid: String
    let videoConfig: VideoConfig
    let callAuthenticator: MockCallAuthenticator
    let webRTCAuthenticator: MockWebRTCAuthenticator
    let coordinator: WebRTCCoordinator
    let sfuStack: MockSFUStack
    let rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory
    let internetConnection: MockInternetConnection

    init(
        user: User = .dummy(),
        apiKey: String = .unique,
        callCid: String = "default:\(String.unique)",
        videoConfig: VideoConfig = .dummy(),
        callAuthenticator: MockCallAuthenticator = .init(),
        webRTCAuthenticator: MockWebRTCAuthenticator = .init(),
        sfuStack: MockSFUStack = .init(),
        rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory = .init(),
        internetConnection: MockInternetConnection = .init()
    ) {
        self.user = user
        self.apiKey = apiKey
        self.callCid = callCid
        self.videoConfig = videoConfig
        self.callAuthenticator = callAuthenticator
        self.webRTCAuthenticator = webRTCAuthenticator
        self.sfuStack = sfuStack
        self.rtcPeerConnectionCoordinatorFactory = rtcPeerConnectionCoordinatorFactory
        self.internetConnection = internetConnection
        coordinator = .init(
            user: user,
            apiKey: apiKey,
            callCid: callCid,
            videoConfig: videoConfig,
            callAuthenticator: callAuthenticator,
            rtcPeerConnectionCoordinatorFactory: rtcPeerConnectionCoordinatorFactory
        )

        InjectedValues[\.internetConnectionObserver] = internetConnection
    }
}
