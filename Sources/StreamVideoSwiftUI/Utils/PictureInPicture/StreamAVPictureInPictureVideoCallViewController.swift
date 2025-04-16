//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

@available(iOS 15.0, *)
final class StreamAVPictureInPictureVideoCallViewController: AVPictureInPictureVideoCallViewController {

    private let store: PictureInPictureStore
    private let contentView: UIView

    private let disposableBag = DisposableBag()

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    required init(
        store: PictureInPictureStore
    ) {
        self.store = store
        contentView = UIHostingController(
            rootView: StreamPictureInPictureContent(store: store)
        ).view

        super.init(nibName: nil, bundle: nil)

        preferredContentSize = store.state.preferredContentSize

        store
            .publisher(for: \.preferredContentSize)
            .removeDuplicates()
            .filter { $0 != .zero }
            .receive(on: DispatchQueue.main)
            .log(.debug, subsystems: .pictureInPicture) { "PreferredContent size will be updated to \($0)." }
            .assign(to: \.preferredContentSize, onWeak: self)
            .store(in: disposableBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.bounds = view.bounds
        store.dispatch(.setContentSize(view.bounds.size))
    }
}
