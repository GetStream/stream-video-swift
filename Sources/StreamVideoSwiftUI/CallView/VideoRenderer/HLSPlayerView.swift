//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamVideo
import UIKit

/// A view whose layer shows the frames of an `AVPlayer`.
///
/// While the app is in the background the layer lets go of the player. iOS
/// pauses a player that stays attached to a layer, and nothing resumes it
/// afterwards. A detached player keeps playing the audio.
///
/// The layer keeps the player while Picture in Picture is active and shows
/// this layer for the call of the store, because the window draws it.
final class HLSPlayerView: UIView {

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    @Injected(\.pictureInPictureAdapter) private var pictureInPictureAdapter

    var playerLayer: AVPlayerLayer {
        // Safe: UIKit creates `layer` from `layerClass`, so it is always an
        // `AVPlayerLayer`. Apple documents this pattern for AVPlayerLayer.
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    /// The player the view shows when the app is not in the background.
    private var requestedPlayer: AVPlayer?
    private var isInBackground = false
    private var isPictureInPictureActive = false
    private var stateObserver: AnyCancellable?
    private var pictureInPictureObserver: AnyCancellable?

    var player: AVPlayer? {
        get { requestedPlayer }
        set {
            requestedPlayer = newValue
            observePictureInPicture()
            updateLayerPlayer()
        }
    }

    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        observeApplicationState()
        observePictureInPicture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observeApplicationState()
        observePictureInPicture()
    }

    // MARK: - Private Helpers

    private func observeApplicationState() {
        stateObserver = applicationStateAdapter
            .statePublisher
            .map { $0 == .background }
            .removeDuplicates()
            .sink { [weak self] in
                self?.isInBackground = $0
                self?.updateLayerPlayer()
            }
    }

    /// The adapter creates its store a moment after it is first used, so
    /// this retries each time a player is set.
    private func observePictureInPicture() {
        guard
            pictureInPictureObserver == nil,
            let store = pictureInPictureAdapter.store
        else { return }
        pictureInPictureObserver = Publishers.CombineLatest4(
            store.publisher(for: \.isActive),
            store.publisher(for: \.playerLayer),
            store.publisher(for: \.playerLayerCallId),
            store.publisher(for: \.call)
        )
        .map { [weak self] isActive, layer, layerCallId, call in
            isActive && layer === self?.playerLayer && layerCallId == call?.cId
        }
        .removeDuplicates()
        .sink { [weak self] in
            self?.isPictureInPictureActive = $0
            self?.updateLayerPlayer()
        }
    }

    private func updateLayerPlayer() {
        let isDetached = isInBackground && !isPictureInPictureActive
        playerLayer.player = isDetached ? nil : requestedPlayer
    }
}
