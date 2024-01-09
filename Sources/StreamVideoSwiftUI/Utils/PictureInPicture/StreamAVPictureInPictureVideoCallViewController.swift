//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVKit
import Foundation
import StreamVideo
import StreamWebRTC

@available(iOS 15.0, *)
final class StreamAVPictureInPictureVideoCallViewController: AVPictureInPictureVideoCallViewController {

    private let contentView: StreamPictureInPictureVideoRenderer = .init()

    var onSizeUpdate: ((CGSize) -> Void)?

    var track: RTCVideoTrack? {
        get { contentView.track }
        set { contentView.track = newValue }
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
