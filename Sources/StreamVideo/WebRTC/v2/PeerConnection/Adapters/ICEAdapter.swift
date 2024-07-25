//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class ICEAdapter {
    private let queue = UnfairQueue()
    private let peerType: PeerConnectionType
    private let peerConnection: RTCPeerConnection

    private var disposableBag: DisposableBag = .init()
    private var pendingCandidates: [RTCIceCandidate] = []

    var sfuAdapter: SFUAdapter

    init(
        peerType: PeerConnectionType,
        peerConnection: RTCPeerConnection,
        sfuAdapter: SFUAdapter
    ) {
        self.peerType = peerType
        self.peerConnection = peerConnection
        self.sfuAdapter = sfuAdapter

        peerConnection
            .publisher(eventType: RTCPeerConnection.DidGenerateICECandidateEvent.self)
            .sink { [weak self] in self?.trickle($0.candidate) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: RTCPeerConnection.SignalingStateChangedEvent.self)
            .filter { $0.state == .haveRemotePrAnswer }
            .sink { [weak self] _ in self?.addPendingCandidates() }
            .store(in: disposableBag)
    }

    func trickle(_ candidate: RTCIceCandidate) {
        Task {
            do {
                try await sfuAdapter.iceTrickle(
                    candidate,
                    peerType: peerType
                )
            } catch {
                log.error(error)
            }
        }
        .store(in: disposableBag)
    }

    func add(_ candidate: RTCIceCandidate) {
        queue.sync { pendingCandidates.append(candidate) }
        guard
            peerConnection.remoteDescription != nil
        else {
            return
        }
        addPendingCandidates()
    }

    // MARK: - Private helpers

    private func addPendingCandidates() {
        guard !pendingCandidates.isEmpty else {
            return
        }

        var allCandidates: [RTCIceCandidate] = []
        queue.sync {
            allCandidates = pendingCandidates
            pendingCandidates = []
        }

        _ = allCandidates.map { candidate in
            Task { [weak peerConnection] in
                do {
                    try await peerConnection?.add(candidate)
                } catch {
                    log.error(error)
                }
            }
            .store(in: disposableBag)
        }
    }
}
