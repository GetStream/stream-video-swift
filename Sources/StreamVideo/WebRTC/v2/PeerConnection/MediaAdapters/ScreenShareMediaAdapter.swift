//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class ScreenShareMediaAdapter: MediaAdapting, @unchecked Sendable {

    private let sessionID: String
    private let peerConnection: RTCPeerConnection
    private let peerConnectionFactory: PeerConnectionFactory
    private let localMediaManager: LocalMediaAdapting

    private let disposableBag = DisposableBag()
    private let queue = UnfairQueue()

    private var streams: [RTCMediaStream] = []

    let subject: PassthroughSubject<TrackEvent, Never>
    
    var localTrack: RTCMediaStreamTrack? {
        (localMediaManager as? LocalScreenShareMediaAdapter)?.localTrack
    }

    var mid: String? {
        (localMediaManager as? LocalScreenShareMediaAdapter)?.mid
    }

    convenience init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        subject: PassthroughSubject<TrackEvent, Never>,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        self.init(
            sessionID: sessionID,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: LocalScreenShareMediaAdapter(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                subject: subject,
                screenShareSessionProvider: screenShareSessionProvider
            ),
            subject: subject
        )
    }

    init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        localMediaManager: LocalMediaAdapting,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.localMediaManager = localMediaManager
        self.subject = subject

        peerConnection
            .publisher(eventType: RTCPeerConnection.AddedStreamEvent.self)
            .filter { $0.stream.trackType == .screenshare }
            .sink { [weak self] in self?.add($0.stream) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: RTCPeerConnection.RemovedStreamEvent.self)
            .filter { $0.stream.trackType == .screenshare }
            .sink { [weak self] in self?.remove($0.stream) }
            .store(in: disposableBag)
    }

    // MARK: - MediaAdapting

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await localMediaManager.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )
    }

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        try await localMediaManager.didUpdateCallSettings(settings)
    }

    // MARK: - ScreenSharing

    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability]
    ) async throws {
        guard
            let localScreenShareMediaManager = localMediaManager as? LocalScreenShareMediaAdapter
        else {
            return
        }

        try await localScreenShareMediaManager.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        ) { [weak self] in
//            self?.queue.sync { [weak self] in
//                guard let self else { return }
//                streams.forEach { self.peerConnection.remove($0) }
//                streams = []
//            }
        }
    }

    func stopScreenSharing() async throws {
        guard
            let localScreenShareMediaManager = localMediaManager as? LocalScreenShareMediaAdapter
        else {
            return
        }

        try await localScreenShareMediaManager.stopScreenSharing()
    }

    // MARK: - Observers

    private func add(_ stream: RTCMediaStream) {
        queue.sync { streams.append(stream) }
        if let videoTrack = stream.videoTracks.first {
            subject.send(
                .added(
                    id: stream.trackId,
                    trackType: .screenshare,
                    track: videoTrack
                )
            )
        }
    }

    private func remove(_ stream: RTCMediaStream) {
        queue.sync {
            streams = streams.filter { $0.streamId != stream.streamId }
        }
        if let videoTrack = stream.audioTracks.first {
            subject.send(
                .removed(
                    id: stream.streamId,
                    trackType: .screenshare,
                    track: videoTrack
                )
            )
        }
    }
}
