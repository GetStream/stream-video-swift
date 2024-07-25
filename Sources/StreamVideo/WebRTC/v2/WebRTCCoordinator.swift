//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class WebRTCCoordinator: @unchecked Sendable {

    enum ConnectionStrategy {
        case initial(
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions
        )

        case fast

        case clean(
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions
        )

        case rejoin(
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions
        )

        case migrate
    }

    let authenticationAdapter: AuthenticationAdapter
    let localTracksAdapter: LocalTracksAdapter
    let peerConnectionsAdapter: PeerConnectionsAdapter

    let videoConfig: VideoConfig
    let eventNotificationCenter: EventNotificationCenter
    let environment: WebSocketClient.Environment

    private lazy var stateMachine = WebRTCStateMachine(self)

    private let _ownCapabilitiesQueue = UnfairQueue()
    private var _ownCapabilities: Set<OwnCapability> = []
    var ownCapabilities: Set<OwnCapability> {
        get { _ownCapabilitiesQueue.sync { _ownCapabilities } }
        set { _ownCapabilitiesQueue.sync { _ownCapabilities = newValue } }
    }

    init(
        authenticationAdapter: AuthenticationAdapter,
        localTracksAdapter: LocalTracksAdapter,
        peerConnectionsAdapter: PeerConnectionsAdapter,
        videoConfig: VideoConfig,
        eventNotificationCenter: EventNotificationCenter,
        peerConnectionFactory: PeerConnectionFactory,
        environment: WebSocketClient.Environment
    ) {
        self.authenticationAdapter = authenticationAdapter
        self.localTracksAdapter = localTracksAdapter
        self.peerConnectionsAdapter = peerConnectionsAdapter
        self.videoConfig = videoConfig
        self.eventNotificationCenter = eventNotificationCenter
        self.environment = environment

        // It's important to instantiate the stateMachine as soon as possible
        // to ensure it's uniqueness.
        _ = stateMachine
    }

    // MARK: - Actions

    func connect(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    ) {
        do {
            try stateMachine.transition(
                .connecting(
                    self,
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )
            )
        } catch {
            log.error(error)
        }
    }
}
