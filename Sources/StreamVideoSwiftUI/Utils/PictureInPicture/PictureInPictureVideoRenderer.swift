//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC

/// A view that can be used to render an instance of `RTCVideoTrack`
final class PictureInPictureVideoRenderer: UIView, @unchecked Sendable, RTCVideoViewDelegate {
    @Injected(\.videoRenderingOptions) private var videoRenderingOptions

    let store: PictureInPictureStore

    var participant: CallParticipant

    /// The rendering track.
    nonisolated(unsafe) var track: RTCVideoTrack? {
        didSet {
            // Keep the renderer attached to the current track regardless of PiP
            // activation state, so `didChangeVideoSize` can arrive before the
            // first PiP start and seed a correct preferredContentSize.
            guard oldValue != track else { return }
            oldValue?.remove(contentView)
            track?.add(contentView)
        }
    }

    private let usesMetalRenderer = false

    private let contentView: RTCPictureInPictureVideoRenderer = {
        let result = RTCPictureInPictureVideoRenderer(frame: .zero)
        result.resizesFramesToRendererSize = true
        result.isEnabled = false
        return result
    }()

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    init(
        store: PictureInPictureStore,
        participant: CallParticipant,
        track: RTCVideoTrack?
    ) {
        self.store = store
        self.participant = participant
        self.track = track

        super.init(frame: .zero)
        contentView.delegate = self

        // Keep the renderer subscribed for size updates while off-screen, but
        // avoid conversion/enqueue work until we are actually in a window.
        self.track?.add(contentView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    deinit {
        track?.remove(contentView)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Depending on the window we are moving we either start or stop
        // streaming frames from the track.
        self.contentView.isEnabled = window != nil
    }

    // MARK: - RTCVideoViewDelegate

    nonisolated func videoView(
        _ videoView: any RTCVideoRenderer,
        didChangeVideoSize size: CGSize
    ) {
        guard size != .zero else {
            return
        }
        store.dispatch(.setPreferredContentSize(size))
    }
}
