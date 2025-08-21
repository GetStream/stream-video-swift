//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension LocalAudioMediaAdapter.Namespace {

    final class SFUMiddleware: Middleware<LocalAudioMediaAdapter.Namespace>, @unchecked Sendable {

        private var isMuted: Bool?

        override func apply(
            state: LocalAudioMediaAdapter.Namespace.StoreState,
            action: LocalAudioMediaAdapter.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async {
            switch action {
            case let .setPublishingState(value, _):
                switch value {
                case let .processing(isMuted, trackState):
                    self.isMuted = nil
                    await process(
                        state: state,
                        isMuted: isMuted,
                        trackState: trackState,
                        shouldDispatchNestedAction: true
                    )

                case let .muted(trackState):
                    await process(
                        state: state,
                        isMuted: true,
                        trackState: trackState,
                        shouldDispatchNestedAction: false
                    )

                case let .unmuted(trackState):
                    await process(
                        state: state,
                        isMuted: false,
                        trackState: trackState,
                        shouldDispatchNestedAction: false
                    )

                case .idle:
                    break
                }

            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func process(
            state: LocalAudioMediaAdapter.Namespace.StoreState,
            isMuted: Bool,
            trackState: StoreState.TrackState,
            shouldDispatchNestedAction: Bool
        ) async {
            guard
                isMuted != self.isMuted
            else {
                return
            }
            do {
                try await state
                    .sfuAdapter
                    .updateTrackMuteState(
                        .audio,
                        isMuted: isMuted,
                        for: state.sessionID
                    )

                self.isMuted = isMuted

                if shouldDispatchNestedAction {
                    if isMuted {
                        dispatcher?.dispatch(
                            .setPublishingState(
                                .muted(trackState),
                                availableTrackStates: state.availableTrackStates
                            )
                        )
                    } else {
                        dispatcher?.dispatch(
                            .setPublishingState(
                                .unmuted(trackState),
                                availableTrackStates: state.availableTrackStates
                            )
                        )
                    }
                }
            } catch {
                log.error(
                    "Failed to process request for isMuted:\(isMuted) with state:\(state)",
                    subsystems: .webRTC,
                    error: error
                )
                dispatcher?.dispatch(
                    .setPublishingState(
                        .idle,
                        availableTrackStates: state.availableTrackStates
                    )
                )
            }
        }
    }
}
