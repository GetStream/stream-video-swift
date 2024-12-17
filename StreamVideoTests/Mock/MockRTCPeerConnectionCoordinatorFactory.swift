//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding {
    var stubbedBuildCoordinatorResult: [PeerConnectionType: MockRTCPeerConnectionCoordinator] = [:]

    func buildCoordinator(
        sessionId: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        publishOptions: PublishOptions,
        sfuAdapter: SFUAdapter,
        videoCaptureSessionProvider: VideoCaptureSessionProvider,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) -> RTCPeerConnectionCoordinator {
        stubbedBuildCoordinatorResult[peerType] ?? MockRTCPeerConnectionCoordinator(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            publishOptions: publishOptions,
            sfuAdapter: sfuAdapter,
            videoCaptureSessionProvider: videoCaptureSessionProvider,
            screenShareSessionProvider: screenShareSessionProvider
        )
    }
}
