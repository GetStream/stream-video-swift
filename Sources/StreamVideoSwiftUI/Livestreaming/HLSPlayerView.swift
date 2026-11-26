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
final class HLSPlayerView: UIView {

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    private var playerLayer: AVPlayerLayer {
        // Safe: UIKit creates `layer` from `layerClass`, so it is always an
        // `AVPlayerLayer`. Apple documents this pattern for AVPlayerLayer.
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    /// The player the view shows when the app is not in the background.
    private var requestedPlayer: AVPlayer?
    private var isInBackground = false
    private var stateObserver: AnyCancellable?

    var player: AVPlayer? {
        get { requestedPlayer }
        set {
            requestedPlayer = newValue
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
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observeApplicationState()
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

    private func updateLayerPlayer() {
        playerLayer.player = isInBackground ? nil : requestedPlayer
    }
}
