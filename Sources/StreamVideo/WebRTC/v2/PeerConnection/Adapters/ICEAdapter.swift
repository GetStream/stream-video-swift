//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    private var trickledCandidates: [RTCIceCandidate] = []
    private var untrickledCandidates: [RTCIceCandidate] = []

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

        Task {
            await configure()
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
            untrickledCandidates.append(candidate)
            return
        }
        trickleTask(for: candidate)
            .store(in: disposableBag)
    }

    /// Creates a task to trickle an ICE candidate.
    ///
    /// - Parameter candidate: The ICE candidate to trickle.
    /// - Returns: A task that performs the trickle operation.
    private func trickleTask(
        for candidate: RTCIceCandidate
    ) -> Task<Void, Never> {
        Task {
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

                try Task.checkCancellation()

                log.debug(
                    """
                    PeerConnection type:\(peerType) will store trickled candidate for future use.
                    Candidate: \(candidate)
                    """,
                    subsystems: .iceAdapter
                )
                trickledCandidates.append(candidate)
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

    /// Adds an ICE candidate to the peer connection.
    ///
    /// - Parameter candidate: The ICE candidate to add.
    func add(_ candidate: RTCIceCandidate) {
        trickledCandidates.append(candidate)
        guard
            peerConnection.remoteDescription != nil
        else {
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
            .store(in: disposableBag)
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
            trickledCandidates.append(iceCandidate)

            guard
                peerConnection.remoteDescription != nil
            else {
                return
            }

            task(for: iceCandidate)
                .store(in: disposableBag)

        } catch {
            log.error(
                error,
                subsystems: peerType == .publisher
                    ? .peerConnectionPublisher
                    : .peerConnectionSubscriber
            )
        }
    }

    /// Adds all trickled ICE candidates to the peer connection.
    private func addTrickledICECandidates() {
        Task {
            await withTaskGroup(of: Void.self) { [weak self] group in
                guard let self else { return }
                for candidate in await trickledCandidates {
                    group.addTask { @MainActor [weak self] in
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
            }
        }
        .store(in: disposableBag)
    }

    /// Creates a task to add an ICE candidate to the peer connection.
    ///
    /// - Parameter candidate: The ICE candidate to add.
    /// - Returns: A task that adds the candidate to the peer connection.
    private func task(
        for candidate: RTCIceCandidate
    ) -> Task<Void, Never> {
        Task { @MainActor [weak peerConnection] in
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

    /// Configures the ICE adapter, setting up necessary publishers and subscriptions.
    private func configure() async {
        disposableBag.removeAll()

        sfuAdapter
            .$connectionState
            .removeDuplicates()
            .filter { if case .connected = $0 { true } else { false } }
            .sinkTask(storeIn: disposableBag) { [weak self] _ in
                guard let self else { return }
                for candidate in await untrickledCandidates {
                    await trickleTask(for: candidate)
                        .store(in: disposableBag)
                }
            }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.DidGenerateICECandidateEvent.self)
            .log(.debug, subsystems: .iceAdapter) { [peerType] in "PeerConnection type:\(peerType) generated \($0)." }
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.trickle($0.candidate) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.HasRemoteDescription.self)
            .log(.debug, subsystems: .iceAdapter)
            .sinkTask(storeIn: disposableBag) { [weak self] _ in await self?.addTrickledICECandidates() }
            .store(in: disposableBag)

        let _peerType = peerType == .publisher
            ? Stream_Video_Sfu_Models_PeerType.publisherUnspecified
            : .subscriber
        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Models_ICETrickle.self)
            .filter { [_peerType] in $0.peerType == _peerType }
            .log(.debug, subsystems: .iceAdapter)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleICETrickle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .refreshPublisher
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.configure() }
            .store(in: disposableBag)
    }
}
