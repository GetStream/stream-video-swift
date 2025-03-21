//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVKit
import Foundation
import StreamVideo
import StreamWebRTC

/// Describes an object that can be used to present picture-in-picture content.
protocol StreamAVPictureInPictureViewControlling: AnyObject {
    
    /// The closure to call whenever the picture-in-picture window size changes.
    @MainActor
    var onSizeUpdate: (@Sendable(CGSize) -> Void)? { get set }

    /// The track that will be rendered on picture-in-picture window.
    @MainActor
    var track: RTCVideoTrack? { get set }

    /// The preferred size for the picture-in-picture window.
    /// - Important: This should **always** be greater to ``CGSize.zero``. If not, iOS throws
    /// a cryptic error with content `PGPegasus code:-1003`
    @MainActor
    var preferredContentSize: CGSize { get set }

    /// The layer that renders the incoming frames from WebRTC.
    @MainActor
    var displayLayer: CALayer { get }
}

@available(iOS 15.0, *)
final class StreamAVPictureInPictureVideoCallViewController: AVPictureInPictureVideoCallViewController,
    StreamAVPictureInPictureViewControlling {

    private let contentView: StreamPictureInPictureVideoRenderer =
        .init(windowSizePolicy: StreamPictureInPictureAdaptiveWindowSizePolicy())

    nonisolated(unsafe) var onSizeUpdate: (@Sendable(CGSize) -> Void)?

    @MainActor
    var track: RTCVideoTrack? {
        get { contentView.track }
        set { contentView.track = newValue }
    }

    @MainActor
    var displayLayer: CALayer { contentView.displayLayer }

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Initializes a new instance and sets the `preferredContentSize` to `Self.defaultPreferredContentSize`
    /// value.
    required init() {
        super.init(nibName: nil, bundle: nil)
        contentView.pictureInPictureWindowSizePolicy.controller = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.bounds = view.bounds
        onSizeUpdate?(contentView.bounds.size)
    }

    // MARK: - Private helpers

    private func setUp() {
        view.subviews.forEach { $0.removeFromSuperview() }

        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentView.bounds = view.bounds
    }
}
