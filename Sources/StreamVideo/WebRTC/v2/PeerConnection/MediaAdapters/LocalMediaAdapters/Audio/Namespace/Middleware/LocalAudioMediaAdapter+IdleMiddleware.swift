//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension LocalAudioMediaAdapter.Namespace {

    final class IdleMiddleware: Middleware<LocalAudioMediaAdapter.Namespace>, @unchecked Sendable {

        @Injected(\.audioStore) private var audioStore

        override func apply(
            state: LocalAudioMediaAdapter.Namespace.StoreState,
            action: LocalAudioMediaAdapter.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async {
            switch action {
            case let .setCallSettings(value) where state.callSettings != value:
                process(
                    state: state,
                    ownCapabilities: state.ownCapabilities,
                    callSettings: value
                )

            case let .setOwnCapabilities(value) where state.ownCapabilities != value:
                process(
                    state: state,
                    ownCapabilities: value,
                    callSettings: state.callSettings
                )

            case let .setAudioBitrateAndMediaConstraints(audioBitrate, mediaConstraints):
                process(
                    state: state,
                    audioBitrate: audioBitrate,
                    mediaConstraints: mediaConstraints
                )

            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func process(
            state: StoreState,
            ownCapabilities: Set<OwnCapability>,
            callSettings: CallSettings.Audio?
        ) {
            guard
                // 1. Check if user has capability to share audio.
                ownCapabilities.contains(.sendAudio),
                let callSettings
            else {
                dispatcher?.dispatch(
                    .setPublishingState(
                        .idle,
                        availableTrackStates: state.availableTrackStates
                    )
                )
                return
            }

            switch state.publishingState {
            case .idle:
                let (trackState, availableTrackStates) = availableTrackState(
                    availableTrackStates: state.availableTrackStates,
                    mediaConstraints: state.mediaConstraints,
                    audioBitrate: audioStore.state.inputConfiguration.audioBitrate,
                    peerConnectionFactory: state.peerConnectionFactory
                )

                if callSettings.micOn {
                    dispatcher?.dispatch(
                        .setPublishingState(
                            .unmuted(trackState),
                            availableTrackStates: availableTrackStates
                        )
                    )
                } else {
                    dispatcher?.dispatch(
                        .setPublishingState(
                            .muted(trackState),
                            availableTrackStates: availableTrackStates
                        )
                    )
                }

            case let .unmuted(trackState) where callSettings.micOn == false:
                dispatcher?.dispatch(
                    .setPublishingState(
                        .muted(trackState),
                        availableTrackStates: state.availableTrackStates
                    )
                )

            case let .muted(trackState) where callSettings.micOn:
                dispatcher?.dispatch(
                    .setPublishingState(
                        .unmuted(trackState),
                        availableTrackStates: state.availableTrackStates
                    )
                )

            default:
                break
            }
        }

        private func availableTrackState(
            availableTrackStates: [StoreState.TrackState],
            mediaConstraints: RTCMediaConstraints,
            audioBitrate: AudioBitrate,
            peerConnectionFactory: PeerConnectionFactory
        ) -> (StoreState.TrackState, [StoreState.TrackState]) {
            var updatedTrackStates = availableTrackStates

            if let availableTrackState = updatedTrackStates
                .first(where: { $0.mediaConstraints == mediaConstraints && $0.audioBitrate == audioBitrate }) {
                return (availableTrackState, updatedTrackStates)
            } else {
                let audioSource = peerConnectionFactory
                    .makeAudioSource(mediaConstraints)
                let audioTrack = peerConnectionFactory
                    .makeAudioTrack(source: audioSource)

                let trackState = StoreState.TrackState(
                    primaryTrack: audioTrack,
                    audioSource: audioSource,
                    mediaConstraints: mediaConstraints,
                    audioBitrate: audioBitrate,
                    transceiverStorage: .init(for: .audio)
                )

                updatedTrackStates.append(trackState)
                return (trackState, updatedTrackStates)
            }
        }

        private func process(
            state: StoreState,
            audioBitrate: AudioBitrate,
            mediaConstraints: RTCMediaConstraints
        ) {
            guard state.publishingState != .idle else {
                return
            }

            let (trackState, availableTrackStates) = availableTrackState(
                availableTrackStates: state.availableTrackStates,
                mediaConstraints: mediaConstraints,
                audioBitrate: audioBitrate,
                peerConnectionFactory: state.peerConnectionFactory
            )

            switch state.publishingState {
            case .idle:
                break
            case let .processing(isMuted, _):
                dispatcher?.dispatch(
                    .setPublishingState(
                        .processing(isMuted: isMuted, trackState: trackState),
                        availableTrackStates: availableTrackStates
                    )
                )
            case .unmuted:
                dispatcher?.dispatch(
                    .setPublishingState(
                        .processing(isMuted: false, trackState: trackState),
                        availableTrackStates: availableTrackStates
                    )
                )

            case .muted:
                dispatcher?.dispatch(
                    .setPublishingState(
                        .processing(isMuted: true, trackState: trackState),
                        availableTrackStates: availableTrackStates
                    )
                )
            }
        }
    }
}
