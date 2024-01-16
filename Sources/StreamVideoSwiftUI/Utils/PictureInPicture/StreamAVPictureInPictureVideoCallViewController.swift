//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVKit
import Foundation
import StreamVideo
import StreamWebRTC

/// Describes an object that can be used to present Picture in Picture content.
/// - Note: In iOS 15 and above you should be using ``StreamAVPictureInPictureVideoCallViewController``
/// and for earlier versions ``StreamAVPictureInPictureViewController``.
protocol StreamAVPictureInPictureViewControlling {
    
    /// The closure to call whenever the Picture in Picture window size changes.
    var onSizeUpdate: ((CGSize) -> Void)? { get set }

    /// The track that will be rendered on Picture in Picture window.
    var track: RTCVideoTrack? { get set }

    /// The preferred size for the Picture in Picture window.
    /// - Important: This should **always** be greater to ``CGSize.zero``. If not, iOS throws
    /// a cryptic error with content `PGPegasus code:-1003`
    var preferredContentSize: CGSize { get set }

    /// The layer that renders the incoming frames from WebRTC.
    var displayLayer: CALayer { get }
}

@available(iOS 15.0, *)
final class StreamAVPictureInPictureVideoCallViewController: AVPictureInPictureVideoCallViewController, StreamAVPictureInPictureViewControlling {

    private let contentView: StreamPictureInPictureVideoRenderer = .init()

    var onSizeUpdate: ((CGSize) -> Void)?

    var track: RTCVideoTrack? {
        get { contentView.track }
        set { contentView.track = newValue }
    }

    var displayLayer: CALayer { contentView.displayLayer }

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

final class StreamAVPictureInPictureViewController: UIViewController, StreamAVPictureInPictureViewControlling {
    private let contentView: StreamPictureInPictureVideoRenderer = .init()

    var onSizeUpdate: ((CGSize) -> Void)?

    var track: RTCVideoTrack? {
        get { contentView.track }
        set { contentView.track = newValue }
    }

    var displayLayer: CALayer { contentView.displayLayer }

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
