//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class responsible for managing local audio media during a call session.
///
/// `LocalAudioMediaAdapter` handles the configuration, publishing, and
/// updating of local audio tracks within a WebRTC session. It integrates
/// with WebRTC components and supports features like muting, quality updates,
/// and SFU communication.
final class LocalAudioMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    private let store: Store<Namespace>

    /// Initializes a new instance of `LocalAudioMediaAdapter`.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - publishOptions: The options for publishing audio tracks.
    ///   - subject: A publisher that emits track events.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        publishOptions: [PublishOptions.AudioPublishOptions],
        audioSettings: AudioSettings,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        store = Namespace.store(
            initialState: .init(
                sessionID: sessionID,
                streamIds: ["\(sessionID):audio"],
                publishOptions: publishOptions,
                mediaConstraints: .defaultConstraints,
                audioBitrate: InjectedValues[\.audioStore].state.inputConfiguration.audioBitrate,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                availableTrackStates: [],
                callSettings: nil,
                ownCapabilities: [],
                subject: subject,
                publishingState: .idle
            )
        )
    }

    /// Cleans up resources when the instance is deallocated.
    deinit {
        for trackState in store.state.availableTrackStates {
            trackState.transceiverStorage.removeAll()
            log.debug(
                """
                Local audio tracks will be deallocated:
                    primary: \(trackState.primaryTrack.trackId) isEnabled:\(trackState.primaryTrack.isEnabled)
                    clones: \(trackState.transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    // MARK: - LocalMediaManaging

    /// Configures the local audio media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The settings for the call, such as whether audio is enabled.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await store.dispatchSync(.setOwnCapabilities(Set(ownCapabilities)))
    }

    /// Updates the local audio media based on new call settings.
    ///
    /// - Parameter settings: The updated settings for the call.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        try await store.dispatchSync(.setCallSettings(settings.audio))
    }

    /// Updates the publish options for the local audio track.
    ///
    /// - Parameter publishOptions: The new publish options.
    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        store.dispatch(.setPublishOptions(publishOptions.audio))
    }

    /// Returns track information for the local audio tracks.
    ///
    /// - Returns: An array of `Stream_Video_Sfu_Models_TrackInfo` representing
    ///   the local audio tracks.
    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        guard
            let trackState: Namespace.State.TrackState = {
                switch store.state.publishingState {
                case let .muted(trackState), let .unmuted(trackState):
                    return trackState
                default:
                    return nil
                }
            }()
        else {
            return []
        }

        let transceivers = {
            switch collectionType {
            case .allAvailable:
                return trackState
                    .transceiverStorage
                    .map { ($0, $1.transceiver, $1.track) }
            case .lastPublishOptions:
                return store
                    .state
                    .publishOptions
                    .compactMap {
                        if
                            let entry = trackState.transceiverStorage.get(for: $0),
                            entry.transceiver.sender.track != nil {
                            return ($0, entry.transceiver, entry.track)
                        } else {
                            return nil
                        }
                    }
            }
        }()

        return transceivers
            .map { publishOptions, transceiver, track in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .audio
                trackInfo.trackID = track.trackId
                trackInfo.mid = transceiver.mid
                trackInfo.muted = !track.isEnabled
                trackInfo.codec = .init(publishOptions.codec)
                trackInfo.stereo = trackState.mediaConstraints == .hiFiAudioConstraints
                trackInfo.audioBitrateType = .init(trackState.audioBitrate)
                return trackInfo
            }
    }

    /// Updates the publishing quality of the audio track.
    ///
    /// - Parameter layerSettings: An array of `Stream_Video_Sfu_Event_AudioSender`
    ///   objects representing the quality settings for the audio layers.
    ///
    /// This method is intended to apply quality adjustments to the audio track,
    /// but the current implementation is a no-op. Override or extend this method
    /// to provide custom logic for changing the audio track's publish quality.
    ///
    /// - Note: If quality adjustments are not required, this no-op implementation
    ///   can be left unchanged.
    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_AudioSender]
    ) { /* No-op */ }
}
