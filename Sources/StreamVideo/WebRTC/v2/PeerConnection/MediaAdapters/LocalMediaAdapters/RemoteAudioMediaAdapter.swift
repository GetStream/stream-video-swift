//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Observes remote audio receivers on a subscriber peer connection.
///
/// WebRTC exposes remote audio through receiver callbacks rather than local
/// media streams. This adapter converts those callbacks into `TrackEvent`
/// values so shared track storage can attach and detach `RTCAudioTrack`
/// instances from `CallParticipant`.
final class RemoteAudioMediaAdapter: LocalMediaAdapting {

    /// A remote audio receiver and the participant lookup id it belongs to.
    private struct AudioTrack {
        var receiverId: String
        var trackId: String
        var track: RTCAudioTrack

        init?(_ event: StreamRTCPeerConnection.AddedReceiverEvent) {
            guard
                let stream = event.streams.first(where: { $0.trackType == .audio }),
                let audioTrack = event.receiver.track as? RTCAudioTrack
            else {
                return nil
            }

            self.receiverId = event.receiver.receiverId
            self.trackId = stream.trackId
            self.track = audioTrack
        }
    }

    /// A publisher that emits track events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Remote audio adapters never publish local media.
    var isPublishing: Bool { false }

    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    private var audioReceivers: [String: AudioTrack] = [:]

    /// Creates a remote audio adapter.
    ///
    /// - Parameters:
    ///   - subject: The subject used to emit remote audio track events.
    ///   - peerConnection: The subscriber peer connection to observe.
    init(
        subject: PassthroughSubject<TrackEvent, Never>,
        peerConnection: StreamRTCPeerConnectionProtocol
    ) {
        self.subject = subject

        peerConnection
           .publisher(eventType: StreamRTCPeerConnection.AddedReceiverEvent.self)
           .compactMap(AudioTrack.init)
           .receive(on: processingQueue)
           .sink { [weak self] in self?.processAddedTrack($0) }
           .store(in: disposableBag)

        peerConnection
           .publisher(eventType: StreamRTCPeerConnection.RemovedReceiverEvent.self)
           .receive(on: processingQueue)
           .compactMap { [weak self] in self?.audioReceivers[$0.receiver.receiverId] }
           .sink { [weak self] in self?.processRemovedTrack($0) }
           .store(in: disposableBag)
    }

    /// No-op because remote audio does not require local setup.
    ///
    /// - Parameters:
    ///   - settings: Ignored in this implementation.
    ///   - ownCapabilities: Ignored in this implementation.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        /* No-op */
    }

    /// No-op because remote audio is not locally published.
    func publish() async throws {
        /* No-op */
    }

    /// No-op because remote audio is not locally unpublished.
    func unpublish() async throws {
        /* No-op */
    }

    /// Returns no publisher track info for remote audio.
    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] { [] }

    /// No-op because call settings are handled by the publisher audio adapter.
    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        /* No-op */
    }

    /// No-op because local capabilities do not affect remote audio receivers.
    func didUpdateOwnCapabilities(
        _ ownCapabilities: Set<OwnCapability>
    ) { /* No-op */ }

    /// No-op because remote audio does not use publisher options.
    func didUpdatePublishOptions(_ publishOptions: PublishOptions) async throws {
        /* No-op */
    }

    // MARK: - Private Helpers

    private func processAddedTrack(
        _ trackEntry: AudioTrack
    ) {
        audioReceivers[trackEntry.receiverId] = trackEntry

        subject.send(
            .added(
                id: trackEntry.trackId,
                trackType: .audio,
                track: trackEntry.track
            )
        )
    }

    private func processRemovedTrack(
        _ trackEntry: AudioTrack
    ) {
        audioReceivers[trackEntry.receiverId] = nil

        subject.send(
            .removed(
                id: trackEntry.trackId,
                trackType: .audio,
                track: trackEntry.track
            )
        )
    }
}
