//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC

final class MockWebRTCCoordinatorStack: @unchecked Sendable {

    let user: User
    let apiKey: String
    let callCid: String
    let videoConfig: VideoConfig
    let peerConnectionFactory: MockPeerConnectionFactory
    let callAuthenticator: MockCallAuthenticator
    let webRTCAuthenticator: MockWebRTCAuthenticator
    let coordinator: WebRTCCoordinator
    let sfuStack: MockSFUStack
    let rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory
    let internetConnection: MockInternetConnection

    private var healthCheckCancellable: AnyCancellable?

    init(
        user: User = .dummy(),
        apiKey: String = .unique,
        callCid: String = "default:\(String.unique)",
        videoConfig: VideoConfig,
        peerConnectionFactory: MockPeerConnectionFactory = .init(),
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
        self.peerConnectionFactory = peerConnectionFactory
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
            peerConnectionFactory: peerConnectionFactory,
            rtcPeerConnectionCoordinatorFactory: rtcPeerConnectionCoordinatorFactory,
            webRTCAuthenticator: webRTCAuthenticator,
            callAuthentication: callAuthenticator.authenticate
        )

        InjectedValues[\.internetConnectionObserver] = internetConnection
    }

    // MARK: Event Simulation

    func joinResponse(_ participants: [CallParticipant]) {
        var event = Stream_Video_Sfu_Event_JoinResponse()
        event.callState.participants = participants.map { .init($0) }
        sfuStack.receiveEvent(.sfuEvent(.joinResponse(event)))
    }

    func participantJoined(_ participant: CallParticipant) {
        var event = Stream_Video_Sfu_Event_ParticipantJoined()
        event.participant = .init(participant)
        event.callCid = callCid
        sfuStack.receiveEvent(.sfuEvent(.participantJoined(event)))
    }

    func participantLeft(_ participant: CallParticipant) {
        var event = Stream_Video_Sfu_Event_ParticipantLeft()
        event.participant = .init(participant)
        event.callCid = callCid
        sfuStack.receiveEvent(.sfuEvent(.participantLeft(event)))
    }

    func addTrack(
        kind: TrackType,
        for identifier: String
    ) async {
        let track: RTCMediaStreamTrack = await .dummy(
            kind: kind,
            peerConnectionFactory: coordinator.stateAdapter.peerConnectionFactory
        )
        await coordinator.stateAdapter.didAddTrack(
            track,
            type: kind,
            for: identifier
        )
    }

    func removeTrack(kind: TrackType, for identifier: String) async {
        await coordinator.stateAdapter.didRemoveTrack(
            for: identifier,
            type: kind
        )
    }

    func receiveHealthCheck(
        every interval: TimeInterval = 1
    ) {
        healthCheckCancellable = Foundation
            .Timer
            .publish(every: interval, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let event = Stream_Video_Sfu_Event_HealthCheckResponse()
                sfuStack.receiveEvent(.sfuEvent(.healthCheckResponse(event)))
            }
    }
}
