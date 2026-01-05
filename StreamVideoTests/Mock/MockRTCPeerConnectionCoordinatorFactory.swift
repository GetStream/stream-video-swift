//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding, @unchecked Sendable {
    var stubbedBuildCoordinatorResult: [PeerConnectionType: MockRTCPeerConnectionCoordinator] = [:]

    var stubbedPeerConnectionFactory: PeerConnectionFactory?

    init(
        peerConnectionFactory: PeerConnectionFactory? = nil
    ) {
        self.stubbedPeerConnectionFactory = peerConnectionFactory
    }

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
        screenShareSessionProvider: ScreenShareSessionProvider,
        clientCapabilities: Set<ClientCapability>,
        audioDeviceModule: AudioDeviceModule
    ) -> RTCPeerConnectionCoordinator {
        stubbedBuildCoordinatorResult[peerType] ?? MockRTCPeerConnectionCoordinator(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            peerConnectionFactory: stubbedPeerConnectionFactory ?? peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            publishOptions: publishOptions,
            sfuAdapter: sfuAdapter,
            videoCaptureSessionProvider: videoCaptureSessionProvider,
            screenShareSessionProvider: screenShareSessionProvider,
            clientCapabilities: clientCapabilities,
            audioDeviceModule: audioDeviceModule
        )
    }
}
