//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

actor ICEAdapter: @unchecked Sendable {
    private let sessionID: String
    private let encoder = JSONEncoder()
    private let peerType: PeerConnectionType
    private let peerConnection: RTCPeerConnection

    private var disposableBag: DisposableBag = .init()
    private var trickledCandidates: [RTCIceCandidate] = []
    private var untrickledCandidates: [RTCIceCandidate] = []

    var sfuAdapter: SFUAdapter

    init(
        sessionID: String,
        peerType: PeerConnectionType,
        peerConnection: RTCPeerConnection,
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

    func trickle(_ candidate: RTCIceCandidate) {
        guard case .connected = sfuAdapter.connectionState else {
            untrickledCandidates.append(candidate)
            return
        }
        trickleTask(for: candidate)
            .store(in: disposableBag)
    }

    private func trickleTask(
        for candidate: RTCIceCandidate
    ) -> Task<Void, Never> {
        Task {
            do {
                let iceCandidate = candidate.toIceCandidate()
                let json = try encoder.encode(iceCandidate)
                guard
                    let jsonString = String(data: json, encoding: .utf8)
                else {
                    throw ClientError("PeerConnection type:\(peerType) was unable to trickle generated candidate\(candidate).")
                }

                log.debug(
                    """
                    PeerConnection type:\(peerType) generated candidate while remoteDescription is \(peerConnection
                        .remoteDescription == nil ? "nil" : "non-nil").
                    Candidate: \(candidate)
                    """,
                    subsystems: .iceAdapter
                )

                try await sfuAdapter.iCETrickle(
                    candidate: jsonString,
                    peerType: peerType == .publisher ? .publisherUnspecified : .subscriber,
                    for: sessionID
                )
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

    private func handleICETrickle(
        _ event: Stream_Video_Sfu_Models_ICETrickle
    ) {
        do {
            let iceCandidate = try event.toICECandidate()
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

    private func addTrickledICECandidates() {
        Task {
            await withTaskGroup(of: Void.self) { [weak self] group in
                guard let self else { return }
                for candidate in await trickledCandidates {
                    group.addTask { [weak self] in
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

    private func task(
        for candidate: RTCIceCandidate
    ) -> Task<Void, Never> {
        Task { [weak peerConnection] in
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
            .publisher(eventType: RTCPeerConnection.DidGenerateICECandidateEvent.self)
            .log(.debug, subsystems: .iceAdapter) { [peerType] in "PeerConnection type:\(peerType) generated \($0)." }
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.trickle($0.candidate) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: RTCPeerConnection.HasRemoteDescription.self)
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

extension RTCIceCandidate: @unchecked Sendable {}
extension RTCPeerConnection: @unchecked Sendable {}

extension Stream_Video_Sfu_Models_ICETrickle {

    func toICECandidate() throws -> RTCIceCandidate {
        guard let data = iceCandidate.data(
            using: .utf8,
            allowLossyConversion: false
        ) else {
            throw ClientError.Unexpected()
        }
        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options: .mutableContainers
        ) as? [String: Any], let sdp = json["candidate"] as? String else {
            throw ClientError.Unexpected()
        }

        return RTCIceCandidate(
            sdp: sdp,
            sdpMLineIndex: 0,
            sdpMid: nil
        )
    }
}

extension RTCIceCandidate {

    func toIceCandidate() -> ICECandidate {
        .init(from: self)
    }
}

extension RTCVideoCodecInfo {

    func toSfuCodec() -> Stream_Video_Sfu_Models_Codec {
        var codec = Stream_Video_Sfu_Models_Codec()
        codec.name = name
        return codec
    }
}
