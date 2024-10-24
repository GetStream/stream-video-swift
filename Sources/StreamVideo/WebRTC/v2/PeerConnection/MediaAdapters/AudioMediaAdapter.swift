//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that manages audio media for a call session.
final class AudioMediaAdapter: MediaAdapting, @unchecked Sendable {

    /// The unique identifier for the current session.
    private let sessionID: String

    /// The WebRTC peer connection.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// The factory for creating WebRTC peer connection components.
    private let peerConnectionFactory: PeerConnectionFactory

    /// The audio session manager.
    private let audioSession: AudioSession

    /// The manager for local audio media.
    private let localMediaManager: LocalMediaAdapting

    /// A bag to store disposable resources.
    private let disposableBag = DisposableBag()

    /// A queue for synchronizing access to shared resources.
    private let queue = UnfairQueue()

    /// An array to store active media streams.
    private var streams: [RTCMediaStream] = []

    /// A subject for publishing track events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// The local audio track, if available.
    var localTrack: RTCMediaStreamTrack? {
        (localMediaManager as? LocalAudioMediaAdapter)?.localTrack
    }

    /// The mid (Media Stream Identification) of the local audio track, if available.
    var mid: String? { (localMediaManager as? LocalAudioMediaAdapter)?.mid }

    /// Convenience initializer for creating an AudioMediaAdapter with a LocalAudioMediaAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - subject: A subject for publishing track events.
    ///   - audioSession: The audio session manager.
    convenience init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
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

    /// Initializes a new instance of the audio media adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - localMediaManager: The manager for local audio media.
    ///   - subject: A subject for publishing track events.
    ///   - audioSession: The audio session manager.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
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

        // Set up observers for added and removed streams
        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.AddedStreamEvent.self)
            .filter { $0.stream.trackType == .audio }
            .sink { [weak self] in self?.add($0.stream) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.RemovedStreamEvent.self)
            .filter { $0.stream.trackType == .audio }
            .sink { [weak self] in self?.remove($0.stream) }
            .store(in: disposableBag)
    }

    // MARK: - MediaAdapting

    /// Sets up the audio media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to configure the audio.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await localMediaManager.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )
    }

    /// Updates the audio media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        try await localMediaManager.didUpdateCallSettings(settings)
    }

    // MARK: - AudioSession

    /// Updates the audio session state.
    ///
    /// - Parameter isEnabled: Whether the audio session is enabled.
    func didUpdateAudioSessionState(_ isEnabled: Bool) async {
        await audioSession.setAudioSessionEnabled(isEnabled)
    }

    /// Updates the audio session speaker state.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether the speaker is enabled.
    ///   - audioSessionEnabled: Whether the audio session is enabled.
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

    /// Adds a new audio stream and notifies observers.
    ///
    /// - Parameter stream: The audio stream to add.
    private func add(_ stream: RTCMediaStream) {
        queue.sync { streams.append(stream) }
        stream.audioTracks.forEach {
            subject.send(
                .added(
                    id: stream.trackId,
                    trackType: .audio,
                    track: $0
                )
            )
        }
    }

    /// Removes an audio stream and notifies observers.
    ///
    /// - Parameter stream: The audio stream to remove.
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
