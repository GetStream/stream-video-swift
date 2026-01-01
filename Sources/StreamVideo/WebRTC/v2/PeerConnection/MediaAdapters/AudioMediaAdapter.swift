//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    /// Convenience initializer for creating an AudioMediaAdapter with a LocalAudioMediaAdapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - publishOptions: The options for publishing audio.
    ///   - subject: A subject for publishing track events.
    convenience init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        publishOptions: [PublishOptions.AudioPublishOptions],
        subject: PassthroughSubject<TrackEvent, Never>
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
                publishOptions: publishOptions,
                subject: subject
            ),
            subject: subject
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
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        localMediaManager: LocalMediaAdapting,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.localMediaManager = localMediaManager
        self.subject = subject

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

    /// Retrieves track information for a specified collection type.
    ///
    /// - Parameter collectionType: The type of track information collection.
    /// - Returns: An array of `Stream_Video_Sfu_Models_TrackInfo` objects.
    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        localMediaManager.trackInfo(for: collectionType)
    }

    /// Updates the audio media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        try await localMediaManager.didUpdateCallSettings(settings)
    }

    /// Updates the publish options for the audio media adapter.
    ///
    /// - Parameter publishOptions: The new publish options to be applied.
    /// - Throws: An error if the update fails.
    /// - Note: This function is asynchronous and may throw an error.
    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        try await localMediaManager.didUpdatePublishOptions(publishOptions)
    }

    /// Changes the publish quality of the audio media adapter.
    ///
    /// - Parameter layerSettings: An array of `Stream_Video_Sfu_Event_AudioSender`
    ///   objects representing the new layer settings.
    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_AudioSender]
    ) {
        (localMediaManager as? LocalAudioMediaAdapter)?
            .changePublishQuality(with: layerSettings)
    }

    // MARK: - Observers

    /// Adds a new audio stream and notifies observers.
    ///
    /// - Parameter stream: The audio stream to add.
    private func add(_ stream: RTCMediaStream) {
        queue.sync { streams.append(stream) }

        stream
            .audioTracks
            .map {
                TrackEvent.added(
                    id: stream.trackId,
                    trackType: .audio,
                    track: $0
                )
            }
            .forEach { subject.send($0) }
    }

    /// Removes an audio stream and notifies observers.
    ///
    /// - Parameter stream: The audio stream to remove.
    private func remove(_ stream: RTCMediaStream) {
        queue.sync {
            streams = streams.filter { $0.streamId != stream.streamId }
        }

        stream
            .audioTracks
            .map {
                TrackEvent.removed(
                    id: stream.trackId,
                    trackType: .audio,
                    track: $0
                )
            }
            .forEach { subject.send($0) }
    }
}
