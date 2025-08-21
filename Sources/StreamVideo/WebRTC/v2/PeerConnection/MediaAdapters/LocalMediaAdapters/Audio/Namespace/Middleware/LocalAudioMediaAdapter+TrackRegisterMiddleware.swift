//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension LocalAudioMediaAdapter.Namespace {

    final class TrackRegisterMiddleware: Middleware<LocalAudioMediaAdapter.Namespace>, @unchecked Sendable {

        private var registeredTrackIDs: Set<String> = []

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
                    guard
                        !isMuted,
                        registeredTrackIDs.contains(trackState.primaryTrack.trackId)
                    else {
                        return
                    }
                    state
                        .subject
                        .send(
                            .added(
                                id: state.sessionID,
                                trackType: .audio,
                                track: trackState.primaryTrack
                            )
                        )

                default:
                    break
                }

            default:
                break
            }
        }
    }
}
