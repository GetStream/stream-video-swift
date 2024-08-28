//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class AudioMediaAdapter: MediaAdapting, @unchecked Sendable {

    private let sessionID: String
    private let peerConnection: RTCPeerConnection
    private let peerConnectionFactory: PeerConnectionFactory
    private let audioSession: AudioSession
    private let localMediaManager: LocalMediaAdapting

    private let disposableBag = DisposableBag()
    private let queue = UnfairQueue()

    private var streams: [RTCMediaStream] = []

    let subject: PassthroughSubject<TrackEvent, Never>

    var localTrack: RTCMediaStreamTrack? {
        (localMediaManager as? LocalAudioMediaAdapter)?.localTrack
    }

    var mid: String? { (localMediaManager as? LocalAudioMediaAdapter)?.mid }

    convenience init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        subject: PassthroughSubject<TrackEvent, Never>,
        audioSession: AudioSession
    ) {
        self.init(
            sessionID: sessionID,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: LocalAudioMediaAdapter(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                audioSession: audioSession,
                subject: subject
            ),
            subject: subject,
            audioSession: audioSession
        )
    }

    init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        localMediaManager: LocalMediaAdapting,
        subject: PassthroughSubject<TrackEvent, Never>,
        audioSession: AudioSession
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.localMediaManager = localMediaManager
        self.subject = subject
        self.audioSession = audioSession

        peerConnection
            .publisher(eventType: RTCPeerConnection.AddedStreamEvent.self)
            .filter { $0.stream.trackType == .audio }
            .sink { [weak self] in self?.add($0.stream) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: RTCPeerConnection.RemovedStreamEvent.self)
            .filter { $0.stream.trackType == .audio }
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

    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        try await localMediaManager.didUpdateCallSettings(settings)
    }

    // MARK: - AudioSession

    func didUpdateAudioSessionState(_ isEnabled: Bool) async {
        await audioSession.setAudioSessionEnabled(isEnabled)
    }

    func didUpdateAudioSessionSpeakerState(
        _ isEnabled: Bool,
        with audioSessionEnabled: Bool
    ) async {
        await audioSession.configure(
            audioOn: audioSessionEnabled,
            speakerOn: isEnabled
        )
    }

    // MARK: - Observers

    private func add(_ stream: RTCMediaStream) {
        queue.sync { streams.append(stream) }
        if let audioTrack = stream.audioTracks.first {
            subject.send(
                .added(
                    id: stream.trackId,
                    trackType: .audio,
                    track: audioTrack
                )
            )
        }
    }

    private func remove(_ stream: RTCMediaStream) {
        queue.sync {
            streams = streams.filter { $0.streamId != stream.streamId }
            if let audioTrack = stream.audioTracks.first {
                subject.send(
                    .removed(
                        id: stream.streamId,
                        trackType: .audio,
                        track: audioTrack
                    )
                )
            }
        }
    }
}
