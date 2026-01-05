//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

/// Manages video track state for Picture-in-Picture functionality.
///
/// Ensures proper track enabling/disabling when Picture-in-Picture is active
/// and maintains track state consistency.
final class PictureInPictureTrackStateAdapter: @unchecked Sendable {

    @Injected(\.screenProperties) private var screenProperties

    private enum DisposableKey: String { case timePublisher }

    private let store: PictureInPictureStore
    private let disposableBag = DisposableBag()
    private var content: PictureInPictureContent {
        didSet { didUpdate(content, oldValue: oldValue) }
    }

    private var activeTracksBeforePiP: [RTCVideoTrack] = []

    /// Creates a new track state adapter.
    ///
    /// - Parameter store: The store managing Picture-in-Picture state
    init(store: PictureInPictureStore) {
        self.store = store
        content = store.state.content

        store
            .publisher(for: \.isActive)
            .removeDuplicates()
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.didUpdate($0) }
            .store(in: disposableBag)

        store
            .publisher(for: \.content)
            .removeDuplicates()
            .assign(to: \.content, onWeak: self)
            .store(in: disposableBag)
    }

    // MARK: - Private helpers

    /// Updates track state based on Picture-in-Picture activation.
    ///
    /// - Parameter isActive: Whether Picture-in-Picture is active
    @MainActor
    private func didUpdate(_ isActive: Bool) {
        disposableBag.remove(DisposableKey.timePublisher.rawValue)

        guard isActive else {
            activeTracksBeforePiP.forEach { $0.isEnabled = true }
            activeTracksBeforePiP = []
            log.debug("Track activeState observation is now inactive.", subsystems: .pictureInPicture)
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

        DefaultTimer
            .publish(every: screenProperties.refreshRate)
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] _ in self?.checkTracksState() }
            .store(in: disposableBag, key: DisposableKey.timePublisher.rawValue)

        log.debug("Track activeState observation is now active.", subsystems: .pictureInPicture)
    }

    /// Updates track state when Picture-in-Picture content changes.
    private func didUpdate(
        _ content: PictureInPictureContent,
        oldValue: PictureInPictureContent
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

        newTrack?.isEnabled = true
        switch oldValue {
        case let .participant(_, participant, track) where track != nil:
            track?.isEnabled = false
            log.debug(
                "Track activeState observation has disabled the track:\(track?.trackId ?? "-") for participant name:\(participant.name).",
                subsystems: .pictureInPicture
            )
        case let .screenSharing(_, participant, track):
            track.isEnabled = false
            log.debug(
                "Track activeState observation has disabled the screenSharing track:\(track.trackId) for participant name:\(participant.name).",
                subsystems: .pictureInPicture
            )
        default:
            break
        }
    }

    /// Ensures the active track remains enabled while Picture-in-Picture is active.
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
