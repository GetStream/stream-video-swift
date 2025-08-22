//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [MockFunctionKey: [MockFunctionInputKey]] = MockRTCPeerConnectionCoordinatorFactory
        .initialStubbedFunctionInput

    enum MockFunctionKey: Hashable, CaseIterable {
        case buildCoordinator
    }

    enum MockFunctionInputKey: Payloadable {
        case buildCoordinator(
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
            audioMediaConstraints: RTCMediaConstraints
        )

        var payload: Any {
            switch self {
            case let .buildCoordinator(
                sessionId,
                peerType,
                peerConnection,
                peerConnectionFactory,
                videoOptions,
                videoConfig,
                callSettings,
                audioSettings,
                publishOptions,
                sfuAdapter,
                videoCaptureSessionProvider,
                screenShareSessionProvider,
                clientCapabilities,
                audioMediaConstraints
            ):
                return (
                    sessionId,
                    peerType,
                    peerConnection,
                    peerConnectionFactory,
                    videoOptions,
                    videoConfig,
                    callSettings,
                    audioSettings,
                    publishOptions,
                    sfuAdapter,
                    videoCaptureSessionProvider,
                    screenShareSessionProvider,
                    clientCapabilities,
                    audioMediaConstraints
                )
            }
        }
    }

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
        screenShareSessionProvider: ScreenShareSessionProvider,
        clientCapabilities: Set<ClientCapability>,
        audioMediaConstraints: RTCMediaConstraints
    ) -> RTCPeerConnectionCoordinator {
        record(
            .buildCoordinator,
            input: .buildCoordinator(
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
                screenShareSessionProvider: screenShareSessionProvider,
                clientCapabilities: clientCapabilities,
                audioMediaConstraints: audioMediaConstraints
            )
        )

        return stubbedBuildCoordinatorResult[peerType] ?? MockRTCPeerConnectionCoordinator(
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
            screenShareSessionProvider: screenShareSessionProvider,
            clientCapabilities: clientCapabilities,
            audioMediaConstraints: audioMediaConstraints
        )
    }
}
