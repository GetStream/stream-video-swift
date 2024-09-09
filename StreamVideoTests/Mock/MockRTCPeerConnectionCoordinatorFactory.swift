//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding {
    func buildCoordinator(
        sessionId: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        sfuAdapter: SFUAdapter,
        audioSession: AudioSession,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) -> RTCPeerConnectionCoordinator {
        MockRTCPeerConnectionCoordinator(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: sfuAdapter,
            audioSession: audioSession,
            screenShareSessionProvider: screenShareSessionProvider
        )
    }
}
