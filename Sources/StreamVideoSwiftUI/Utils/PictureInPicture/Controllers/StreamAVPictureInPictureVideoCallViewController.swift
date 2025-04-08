//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import Foundation
import StreamVideo
import StreamWebRTC

/// Describes an object that can be used to present picture-in-picture content.
protocol StreamAVPictureInPictureViewControlling: AnyObject {

    /// The preferred size for the picture-in-picture window.
    /// - Important: This should **always** be greater to ``CGSize.zero``. If not, iOS throws
    /// a cryptic error with content `PGPegasus code:-1003`
    @MainActor
    init(dataPipeline: PictureInPictureDataPipeline)
}

@available(iOS 15.0, *)
final class StreamAVPictureInPictureVideoCallViewController: AVPictureInPictureVideoCallViewController,
    StreamAVPictureInPictureViewControlling {

    private let contentView: StreamPictureInPictureVideoRenderer
    private let dataPipeline: PictureInPictureDataPipeline
    private var preferredContentSizeCancellable: AnyCancellable?

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @MainActor
    required init(dataPipeline: PictureInPictureDataPipeline) {
        contentView = .init(dataPipeline: dataPipeline)
        self.dataPipeline = dataPipeline
        super.init(nibName: nil, bundle: nil)
        preferredContentSizeCancellable = dataPipeline
            .sizeEventPublisher
            .compactMap {
                switch $0 {
                case let .setPreferredSize(size) where size != .zero:
                    return size
                default:
                    return nil
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.preferredContentSize, onWeak: self)

        preferredContentSize = .init(width: 640, height: 480)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.bounds = view.bounds
        dataPipeline.contentSizeUpdated(contentView.bounds.size)
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
