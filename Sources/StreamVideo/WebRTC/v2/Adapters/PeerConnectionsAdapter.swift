//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class PeerConnectionsAdapter {
    
    private let peerConnectionFactory: PeerConnectionFactory
    private let localTrackProvider: (TrackType) -> RTCMediaStreamTrack?
    private let _connectionsStorageQueue = UnfairQueue()
    private var _connectionStorage: [PeerConnectionType: RTCPeerConnectionCoordinator] = [:]

    var sfuAdapter: SFUAdapter? {
        didSet {
            guard let sfuAdapter else { return }
            _connectionsStorageQueue.sync {
                _connectionStorage[.publisher]?.sfuAdapter = sfuAdapter
                _connectionStorage[.subscriber]?.sfuAdapter = sfuAdapter
            }
        }
    }

    var callSettings: CallSettings {
        didSet {
            _connectionsStorageQueue.sync {
                _connectionStorage[.publisher]?.callSettings = callSettings
                _connectionStorage[.subscriber]?.callSettings = callSettings
            }
        }
    }

    var videoOptions: VideoOptions {
        didSet {
            _connectionsStorageQueue.sync {
                _connectionStorage[.publisher]?.videoOptions = videoOptions
                _connectionStorage[.subscriber]?.videoOptions = videoOptions
            }
        }
    }

    var audioSettings: AudioSettings {
        didSet {
            _connectionsStorageQueue.sync {
                _connectionStorage[.publisher]?.audioSettings = audioSettings
                _connectionStorage[.subscriber]?.audioSettings = audioSettings
            }
        }
    }

    var connectOptions: ConnectOptions

    init(
        peerConnectionFactory: PeerConnectionFactory,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        audioSettings: AudioSettings,
        connectOptions: ConnectOptions,
        localTrackProvider: @escaping (TrackType) -> RTCMediaStreamTrack?
    ) {
        self.peerConnectionFactory = peerConnectionFactory
        self.callSettings = callSettings
        self.videoOptions = videoOptions
        self.audioSettings = audioSettings
        self.connectOptions = connectOptions
        self.localTrackProvider = localTrackProvider
    }

    func makeTemporaryOffer(
        connectOptions: ConnectOptions
    ) async throws -> RTCSessionDescription {
        guard let sfuAdapter else {
            throw ClientError("Some of the required information (e.g SFUAdapter) are unavailable.")
        }

        let tempPeerConnection = RTCPeerConnectionCoordinator(
            sessionId: sfuAdapter.sessionId,
            peerType: .subscriber,
            videoOptions: videoOptions,
            callSettings: callSettings,
            audioSettings: audioSettings,
            peerConnection: try peerConnectionFactory.makePeerConnection(
                configuration: connectOptions.rtcConfiguration,
                constraints: .defaultConstraints
            ),
            sfuAdapter: sfuAdapter,
            trackIdProvider: { _, _ in "" }
        )

        if let localAudioTrack = localTrackProvider(.audio) as? RTCAudioTrack {
            tempPeerConnection.execute(
                .addTrack(
                    localAudioTrack,
                    trackType: .audio,
                    streamIds: ["temp-audio"]
                )
            )
        }

        if let localVideoTrack = localTrackProvider(.video) as? RTCVideoTrack {
            tempPeerConnection.execute(
                .addTransceiver(
                    localVideoTrack,
                    trackType: .video,
                    direction: .recvOnly,
                    streamIds: ["temp-video"]
                )
            )
        }

        let offer = try await tempPeerConnection.createOffer()
        tempPeerConnection.close()
        return offer
    }

    func setupIfRequired(
        connectionOfType connectionType: PeerConnectionType,
        trackIdProvider: @escaping (PeerConnectionType, TrackType) -> String
    ) throws {
        guard let sfuAdapter else {
            throw ClientError("Some of the required information (e.g SFUAdapter) are unavailable.")
        }

        guard
            _connectionsStorageQueue.sync({ _connectionStorage[connectionType] }) == nil
        else {
            return
        }

        let coordinator = RTCPeerConnectionCoordinator(
            sessionId: sfuAdapter.sessionId,
            peerType: connectionType,
            videoOptions: videoOptions,
            callSettings: callSettings,
            audioSettings: audioSettings,
            peerConnection: try peerConnectionFactory.makePeerConnection(
                configuration: connectOptions.rtcConfiguration,
                constraints: .defaultConstraints
            ),
            sfuAdapter: sfuAdapter,
            trackIdProvider: trackIdProvider
        )

        _connectionsStorageQueue.sync { _connectionStorage[connectionType] = coordinator }
    }

    func closeConnections(of types:[PeerConnectionType]) {
        types.forEach { peerConnectionType in
            guard
                let peerConnectionCoordinator = _connectionsStorageQueue.sync(
                    { _connectionStorage[peerConnectionType] }
                )
            else {
                return
            }

            peerConnectionCoordinator.close()
            _connectionsStorageQueue.sync {
                _connectionStorage[peerConnectionType] = nil
            }
        }
    }
}
