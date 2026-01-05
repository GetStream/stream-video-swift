//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Manages ICE (Interactive Connectivity Establishment) operations for WebRTC. The adapter is bound to
/// the SFUAdapter and PeerConnection instance.
/// One of the main tasks the adapter fulfils, is to maintain a storage of already trickled ICE candidates
/// and include them to the peer connection if that's needed again.
///
/// Handles trickle ICE, candidate addition, and coordinates with SFU adapter.
actor ICEAdapter: @unchecked Sendable {
    private let sessionID: String
    private let encoder = JSONEncoder()
    private let peerType: PeerConnectionType
    private let peerConnection: StreamRTCPeerConnectionProtocol
    private let sfuAdapter: SFUAdapter

    private var disposableBag: DisposableBag = .init()

    private var pendingSFUCandidates: [RTCIceCandidate] = []
    private var pendingLocalCandidates: [RTCIceCandidate] = []

    private let executor = DispatchQueueExecutor()
    nonisolated var unownedExecutor: UnownedSerialExecutor { .init(ordinary: executor) }

    /// Initializes the ICEAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: Unique identifier for the session.
    ///   - peerType: Type of peer connection (publisher or subscriber).
    ///   - peerConnection: The WebRTC peer connection.
    ///   - sfuAdapter: Adapter for SFU communication.
    init(
        sessionID: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        sfuAdapter: SFUAdapter
    ) {
        self.sessionID = sessionID
        self.peerType = peerType
        self.peerConnection = peerConnection
        self.sfuAdapter = sfuAdapter

        Task(disposableBag: disposableBag) { [weak self] in
            await self?.configure()
        }
    }

    func stopObserving() {
        disposableBag.removeAll()
    }

    /// Trickles an ICE candidate.
    ///
    /// - Parameter candidate: The ICE candidate to trickle.
    func trickle(_ candidate: RTCIceCandidate) {
        guard case .connected = sfuAdapter.connectionState else {
            pendingLocalCandidates.append(candidate)
            return
        }
        trickleTask(for: candidate)
    }

    /// Adds an ICE candidate to the peer connection.
    ///
    /// - Parameter candidate: The ICE candidate to add.
    func add(_ candidate: RTCIceCandidate) {
        guard
            peerConnection.remoteDescription != nil
        else {
            pendingLocalCandidates.append(candidate)
            log.debug(
                """
                PeerConnection type:\(peerType) doesn't have remoteDescription. Hold candidate for now.
                Candidate: \(candidate)
                """,
                subsystems: .iceAdapter
            )
            return
        }

        log.debug(
            """
            PeerConnection type:\(peerType) has remoteDescription. Adding candidate now
            Candidate: \(candidate)
            """,
            subsystems: .iceAdapter
        )
        task(for: candidate)
    }

    // MARK: - Private helpers

    /// Creates a task to trickle an ICE candidate.
    ///
    /// - Parameter candidate: The ICE candidate to trickle.
    /// - Returns: A task that performs the trickle operation.
    private func trickleTask(
        for candidate: RTCIceCandidate
    ) {
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            do {
                let iceCandidate = ICECandidate(from: candidate)
                let json = try encoder.encode(iceCandidate)
                guard
                    let jsonString = String(data: json, encoding: .utf8)
                else {
                    throw ClientError("PeerConnection type:\(peerType) was unable to trickle generated candidate\(candidate).")
                }

                try Task.checkCancellation()

                log.debug(
                    """
                    PeerConnection type:\(peerType) generated candidate while remoteDescription.
                    Candidate: \(candidate)
                    """,
                    subsystems: .iceAdapter
                )

                try Task.checkCancellation()

                try await sfuAdapter.iCETrickle(
                    candidate: jsonString,
                    peerType: peerType == .publisher ? .publisherUnspecified : .subscriber,
                    for: sessionID
                )
            } catch {
                log.error(
                    error,
                    subsystems: peerType == .publisher
                        ? .peerConnectionPublisher
                        : .peerConnectionSubscriber
                )
            }
        }
    }

    // MARK: - Private helpers

    /// Handles an ICE trickle event from the SFU.
    ///
    /// - Parameter event: The ICE trickle event to handle.
    private func handleICETrickle(
        _ event: Stream_Video_Sfu_Models_ICETrickle
    ) {
        do {
            let iceCandidate = try RTCIceCandidate(event)

            guard
                peerConnection.remoteDescription != nil
            else {
                pendingSFUCandidates.append(iceCandidate)
                return
            }

            task(for: iceCandidate)

        } catch {
            log.error(
                error,
                subsystems: peerType == .publisher
                    ? .peerConnectionPublisher
                    : .peerConnectionSubscriber
            )
        }
    }

    /// Creates a task to add an ICE candidate to the peer connection.
    ///
    /// - Parameter candidate: The ICE candidate to add.
    /// - Returns: A task that adds the candidate to the peer connection.
    private func task(
        for candidate: RTCIceCandidate
    ) {
        Task(disposableBag: disposableBag) { @MainActor [weak peerConnection, peerType] in
            guard let peerConnection else { return }
            do {
                try Task.checkCancellation()
                try await peerConnection.add(candidate)
            } catch {
                log.error(
                    error,
                    subsystems: peerType == .publisher
                        ? .peerConnectionPublisher
                        : .peerConnectionSubscriber
                )
            }
        }
    }

    /// Processes and sends all pending local ICE candidates to the SFU. This method
    /// is called when the connection state changes to connected, ensuring that any
    /// candidates generated while disconnected are properly transmitted.
    ///
    /// The method iterates through all pending local candidates and creates a
    /// trickle task for each one. After processing, the pending candidates array
    /// is cleared.
    ///
    /// - Note: This method is typically called as part of the connection state
    ///   change handling in the configure() method.
    private func drainPendingLocalCandidates() async {
        for candidate in pendingLocalCandidates {
            trickleTask(for: candidate)
        }
        pendingLocalCandidates = []
    }

    /// Processes and adds all pending ICE candidates from the SFU to the peer
    /// connection. This method is called to handle accumulated ICE candidates
    /// that were received while the peer connection was not ready.
    ///
    /// The method processes candidates concurrently using a task group, with
    /// retry logic for each candidate addition. If a candidate fails to be
    /// added, the error is logged but the process continues for other
    /// candidates.
    ///
    /// - Note: After processing, the pending candidates array is cleared
    ///   regardless of success or failure of individual additions.
    private func drainPendingSFUCandidates() async {
        let candidates = pendingSFUCandidates
        for candidate in candidates {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
                do {
                    try Task.checkCancellation()
                    try await executeTask(retryPolicy: .fastAndSimple) { [weak self] in
                        try Task.checkCancellation()
                        try await self?.peerConnection.add(candidate)
                    }
                } catch {
                    log.error(
                        error,
                        subsystems: peerType == .publisher
                            ? .peerConnectionPublisher
                            : .peerConnectionSubscriber
                    )
                }
            }
        }
        pendingSFUCandidates = []
    }

    /// Configures the ICE adapter, setting up necessary publishers and subscriptions.
    private func configure() async {
        disposableBag.removeAll()

        sfuAdapter
            .$connectionState
            .removeDuplicates()
            .filter { if case .connected = $0 { true } else { false } }
            .sinkTask(on: self, storeIn: disposableBag) { executor, _ in
                await executor.drainPendingLocalCandidates()
            }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.DidGenerateICECandidateEvent.self)
            .log(.debug, subsystems: .iceAdapter) { [peerType] in "PeerConnection type:\(peerType) generated \($0)." }
            .sinkTask(on: self, storeIn: disposableBag) { await $0.trickle($1.candidate) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.HasRemoteDescription.self)
            .log(.debug, subsystems: .iceAdapter)
            .sinkTask(on: self, storeIn: disposableBag) { executor, _ in await executor.drainPendingSFUCandidates() }
            .store(in: disposableBag)

        let _peerType = peerType == .publisher
            ? Stream_Video_Sfu_Models_PeerType.publisherUnspecified
            : .subscriber

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Models_ICETrickle.self)
            .filter { [_peerType] in $0.peerType == _peerType }
            .log(.debug, subsystems: .iceAdapter)
            .sinkTask(on: self, storeIn: disposableBag) { await $0.handleICETrickle($1) }
            .store(in: disposableBag)

        sfuAdapter
            .refreshPublisher
            .sinkTask(on: self, storeIn: disposableBag) { executor, _ in await executor.configure() }
            .store(in: disposableBag)
    }
}
