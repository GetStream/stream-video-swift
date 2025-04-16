//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

/// StreamPictureInPictureTrackStateAdapter serves as an adapter for managing the state of a video track
/// used for picture-in-picture functionality. It can enable or disable observers based on its isEnabled property
/// and ensures that the active track is always enabled when necessary.
final class StreamPictureInPictureTrackStateAdapter: @unchecked Sendable {

    private enum DisposableKey: String { case timePublisher }

    private let store: PictureInPictureStore
    private let disposableBag = DisposableBag()
    private var content: StreamPictureInPictureContentState {
        didSet { didUpdate(content, oldValue: oldValue) }
    }

    private var activeTracksBeforePiP: [RTCVideoTrack] = []

    init(store: PictureInPictureStore) {
        self.store = store
        content = store.state.content

        store
            .publisher(for: \.isActive)
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdate($0) }
            .store(in: disposableBag)

        store
            .publisher(for: \.content)
            .removeDuplicates()
            .assign(to: \.content, onWeak: self)
            .store(in: disposableBag)
    }

    // MARK: - Private helpers

    ///
    /// - Parameter isActive: A Boolean value indicating whether the observer should be active.
    private func didUpdate(_ isActive: Bool) {
        disposableBag.remove(DisposableKey.timePublisher.rawValue)

        guard isActive else {
            activeTracksBeforePiP.forEach { $0.isEnabled = true }
            activeTracksBeforePiP = []
            log.debug("Track activeState observation is now inactive.", subsystems: .pictureInPicture)
            return
        }

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            if
                let activeTracksBeforePiP = store
                .state
                .call?
                .state
                .participants
                .filter({ $0.track?.isEnabled == true })
                .compactMap(\.track) {
                self.activeTracksBeforePiP = activeTracksBeforePiP
            }

            Timer
                .publish(every: 0.1, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in self?.checkTracksState() }
                .store(in: disposableBag, key: DisposableKey.timePublisher.rawValue)

            log.debug("Track activeState observation is now active.", subsystems: .pictureInPicture)
        }
    }

    private func didUpdate(
        _ content: StreamPictureInPictureContentState,
        oldValue: StreamPictureInPictureContentState
    ) {
        guard store.state.isActive else {
            return
        }

        let currentTrack: RTCVideoTrack? = {
            switch oldValue {
            case let .participant(_, _, track):
                return track
            case let .screenSharing(_, _, track):
                return track
            default:
                return nil
            }
        }()

        let newTrack: RTCVideoTrack? = {
            switch content {
            case let .participant(_, _, track):
                return track
            case let .screenSharing(_, _, track):
                return track
            default:
                return nil
            }
        }()

        guard
            newTrack?.trackId != currentTrack?.trackId
        else {
            return
        }

        switch oldValue {
        case let .participant(_, participant, track) where track != nil:
            track?.isEnabled = false
            log.debug(
                "Track activeState observation has disabled the track:\(track?.trackId ?? "-") for participant name:\(participant.name).",
                subsystems: .pictureInPicture
            )
        case let .screenSharing(_, participant, track):
            log.debug(
                "Track activeState observation has disabled the screenSharing track:\(track.trackId) for participant name:\(participant.name).",
                subsystems: .pictureInPicture
            )
        default:
            break
        }
    }

    /// This private function checks the state of the active track and enables it if it's not already enabled.
    private func checkTracksState() {
        guard store.state.isActive else {
            return
        }
        
        switch content {
        case let .participant(_, participant, track) where track != nil && track?.isEnabled == false:
            track?.isEnabled = true
            log.debug(
                "Track activeState observation has enabled the track:\(track?.trackId ?? "-") for participant name:\(participant.name).",
                subsystems: .pictureInPicture
            )
        case let .screenSharing(_, participant, track) where track.isEnabled == false:
            track.isEnabled = true
            log.debug(
                "Track activeState observation has enabled the screenSharing track:\(track.trackId) for participant name:\(participant.name).",
                subsystems: .pictureInPicture
            )
        default:
            break
        }
    }
}
