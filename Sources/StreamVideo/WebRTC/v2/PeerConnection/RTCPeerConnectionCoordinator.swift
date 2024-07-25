//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class RTCPeerConnectionCoordinator: @unchecked Sendable {

    enum Action {
        case addTrack(
            RTCMediaStreamTrack,
            trackType: TrackType,
            streamIds: [String]
        )

        case addTransceiver(
            RTCMediaStreamTrack,
            trackType: TrackType,
            direction: RTCRtpTransceiverDirection = .sendOnly,
            streamIds: [String]
        )

        case addICECandidate(RTCIceCandidate)

        case restartICE
    }

    private let sessionId: String
    private let peerType: PeerConnectionType
    private let peerConnection: RTCPeerConnection
    private let trackIdProvider: (PeerConnectionType, TrackType) -> String
    private let disposableBag: DisposableBag = .init()

    // MARK: Adapters

    private let mediaAdapter: MediaAdapter
    private let iceAdapter: ICEAdapter
    var sfuAdapter: SFUAdapter {
        didSet {
            iceAdapter.sfuAdapter = sfuAdapter
            negotiate()
        }
    }

    var callSettings: CallSettings
    var videoOptions: VideoOptions
    var audioSettings: AudioSettings

    // MARK: State

    var connectionState: RTCPeerConnectionState { peerConnection.connectionState }

    init(
        sessionId: String,
        peerType: PeerConnectionType,
        videoOptions: VideoOptions,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        peerConnection: RTCPeerConnection,
        sfuAdapter: SFUAdapter,
        trackIdProvider: @escaping (PeerConnectionType, TrackType) -> String
    ) {
        self.sessionId = sessionId
        self.peerType = peerType
        self.videoOptions = videoOptions
        self.callSettings = callSettings
        self.audioSettings = audioSettings
        self.peerConnection = peerConnection
        self.sfuAdapter = sfuAdapter
        self.trackIdProvider = trackIdProvider

        iceAdapter = .init(
            peerType: peerType,
            peerConnection: peerConnection,
            sfuAdapter: sfuAdapter
        )

        mediaAdapter = .init(
            peerConnection: peerConnection,
            videoOptions: videoOptions
        )

        peerConnection
            .publisher
            .sink {
                if $0 is RTCPeerConnection.ICECandidateFailedToGatherEvent {
                    log.warning(
                        """
                        Session ID: \(sessionId)
                        Connection type: \(peerType)
                        SFU: \(sfuAdapter.hostname)
                        Event: \($0)
                        """
                    )
                } else {
                    log.debug(
                        """
                        Session ID: \(sessionId)
                        Connection type: \(peerType)
                        SFU: \(sfuAdapter.hostname)
                        Event: \($0)
                        """
                    )
                }
            }
            .store(in: disposableBag)

        if peerType == .publisher {
            peerConnection
                .publisher(eventType: RTCPeerConnection.ShouldNegotiateEvent.self)
                .map { _ in () }
                .sink { [weak self] in self?.negotiate() }
                .store(in: disposableBag)
        }
    }

    deinit {
        mediaAdapter.close()
        peerConnection.close()
    }

    // MARK: - Actions

    func createOffer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        try await peerConnection.offer(for: constraints)
    }

    func createAnswer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        try await peerConnection.answer(for: constraints)
    }

    func setLocalDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await peerConnection.setLocalDescription(sessionDescription)
    }

    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await peerConnection.setRemoteDescription(sessionDescription)
    }

    func execute(
        _ action: Action
    ) {
        switch action {
        case let .addTrack(track, trackType, streamIds):
            mediaAdapter.publish(track, trackType: trackType, streamIds: streamIds)

        case let .addTransceiver(track, trackType, direction, streamIds):
            mediaAdapter.publish(
                track,
                trackType: trackType,
                direction: direction,
                streamIds: streamIds
            )

        case let .addICECandidate(candidate):
            iceAdapter.add(candidate)

        case .restartICE:
            peerConnection.restartIce()
        }
    }

    func close() {
        peerConnection.close()
    }

    func changePublishQuality(
        enabledRids: Set<String>
    ) {
        mediaAdapter.changePublishQuality(for: .video, enabledRids: enabledRids)
    }

    // MARK: - Start Querying

    func publishes(_ trackType: TrackType) -> Bool {
        mediaAdapter.publishes(trackType)
    }

    // MARK: - Private helpers

    private func negotiate(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let offer = try await self
                    .createOffer(constraints: constraints)
                    .withOpusDTX(audioSettings.opusDtxEnabled)
                    .withRedundantCoding(audioSettings.redundantCodingEnabled)

                try await setLocalDescription(offer)

                let tracksInfo: [Stream_Video_Sfu_Models_TrackInfo] = [
                    TrackType.audio,
                    .video,
                    .screenShare
                ]
                .compactMap { trackType in
                    switch trackType {
                    case .audio where self.callSettings.audioOn:
                        var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                        trackInfo.trackType = .audio
                        trackInfo.trackID = self.trackIdProvider(self.peerType, trackType)
                        return trackInfo

                    case .video:
                        var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                        trackInfo.trackType = .video
                        trackInfo.trackID = self.trackIdProvider(self.peerType, trackType)
                        trackInfo.mid = self.mediaAdapter.mid(for: .video) ?? ""
                        return trackInfo

                    case .screenShare:
                        var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                        trackInfo.trackType = .screenShare
                        trackInfo.trackID = self.trackIdProvider(self.peerType, trackType)
                        trackInfo.mid = self.mediaAdapter.mid(for: .screenShare) ?? ""
                        return trackInfo

                    default:
                        return nil
                    }
                }

                Task(
                    retryPolicy: .fastCheckValue { true }
                ) { [sdp = offer.sdp, weak self] in
                    guard let self else { return }
                    let sessionDescription = try await sfuAdapter.setPublisher(
                        sdp,
                        tracks: tracksInfo
                    )
                    try await setRemoteDescription(sessionDescription)
                }
                .store(in: disposableBag)
            } catch {
                log.error(error)
            }
        }
    }
}
