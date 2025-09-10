//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension LocalAudioMediaAdapter.Namespace {

    final class TransceiverMiddleware: Middleware<LocalAudioMediaAdapter.Namespace>, @unchecked Sendable {

        @Injected(\.callAudioRecorder) private var audioRecorder

        override func apply(
            state: LocalAudioMediaAdapter.Namespace.StoreState,
            action: LocalAudioMediaAdapter.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async {
            switch action {
            case let .setPublishingState(publishingState, _):
                didUpdatePublishingState(publishingState, storeState: state)

            case let .setPublishOptions(publishOptions):
                didUpdatePublishOptions(publishOptions, storeState: state)

            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func didUpdatePublishOptions(
            _ publishOptions: [PublishOptions.AudioPublishOptions],
            storeState: StoreState
        ) {
            guard
                case let .unmuted(trackState) = storeState.publishingState
            else {
                return
            }

            publishOptions
                .forEach {
                    addTransceiverIfRequired(
                        $0,
                        storeState: storeState,
                        trackState: trackState
                    )
                }

            let activePublishOptions = Set(publishOptions)

            trackState
                .transceiverStorage
                .forEach {
                    if activePublishOptions.contains($0.key) {
                        $0.value.track.isEnabled = true
                        $0.value.transceiver.sender.track = $0.value.track
                    } else {
                        $0.value.track.isEnabled = false
                        $0.value.transceiver.sender.track = nil
                    }
                }

            log.debug(
                """
                Local audio tracks updated:
                    PublishOptions: \(publishOptions)
                    TransceiverStorage: \(trackState.transceiverStorage)
                """,
                subsystems: .webRTC
            )
        }

        private func didUpdatePublishingState(
            _ publishingState: StoreState.PublishingState,
            storeState: StoreState
        ) {
            switch publishingState {
            case let .muted(trackState):
                processUnpublish(trackState: trackState)

            case let .unmuted(trackState):
                processPublish(storeState: storeState, trackState: trackState)

            case .processing:
                storeState
                    .availableTrackStates
                    .forEach { processUnpublish(trackState: $0) }

            default:
                break
            }
        }

        private func processPublish(
            storeState: StoreState,
            trackState: StoreState.TrackState
        ) {
            trackState.primaryTrack.isEnabled = true

            storeState
                .publishOptions
                .forEach {
                    addTransceiverIfRequired(
                        $0,
                        storeState: storeState,
                        trackState: trackState
                    )
                }

            let activePublishOptions = Set(storeState.publishOptions)

            trackState
                .transceiverStorage
                .forEach {
                    if activePublishOptions.contains($0.key) {
                        $0.value.track.isEnabled = true
                        $0.value.transceiver.sender.track = $0.value.track
                    } else {
                        $0.value.track.isEnabled = false
                        $0.value.transceiver.sender.track = nil
                    }
                }

            audioRecorder.startRecording()

            log.debug(
                """
                Local audio tracks are now published:
                    primary: \(trackState.primaryTrack.trackId) isEnabled:\(trackState.primaryTrack.isEnabled)
                    clones: \(trackState.transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }

        private func processUnpublish(trackState: StoreState.TrackState) {
            trackState.primaryTrack.isEnabled = false

            trackState
                .transceiverStorage
                .forEach { $0.value.track.isEnabled = false }

            audioRecorder.stopRecording()

            log.debug(
                """
                Local audio tracks are now unpublished:
                    primary: \(trackState.primaryTrack.trackId) isEnabled:\(trackState.primaryTrack.isEnabled)
                    clones: \(trackState.transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }

        private func addTransceiverIfRequired(
            _ options: PublishOptions.AudioPublishOptions,
            storeState: StoreState,
            trackState: StoreState.TrackState
        ) {
            guard
                trackState
                .transceiverStorage
                .contains(key: options) == false
            else {
                return
            }

            let clone = trackState
                .primaryTrack
                .clone(from: storeState.peerConnectionFactory)

            let transceiver = storeState
                .peerConnection
                .addTransceiver(
                    trackType: .audio,
                    with: clone,
                    init: .init(
                        direction: .sendOnly,
                        streamIds: storeState.streamIds,
                        audioOptions: options
                    )
                )

            guard let transceiver else {
                log.warning("Unable to create transceiver for options:\(options).", subsystems: .webRTC)
                return
            }

            trackState
                .transceiverStorage
                .set(transceiver, track: clone, for: options)
        }
    }
}
