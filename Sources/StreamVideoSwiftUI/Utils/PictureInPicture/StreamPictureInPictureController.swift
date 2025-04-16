//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import Foundation
import StreamVideo
import StreamWebRTC
#if canImport(UIKit)
import UIKit
#endif

/// A controller class for picture-in-picture whenever that is possible.
@available(iOS 15.0, *)
final class StreamPictureInPictureController: @unchecked Sendable {

    private enum DisposableKey: String { case isPossible, isActive }

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    // MARK: - Properties

    private let store: PictureInPictureStore

    private let proxyDelegate: StreamPictureInPictureDelegateProxy = .init()

    private var didAppBecomeActiveCancellable: AnyCancellable?

    // MARK: - Private Properties

    /// The AVPictureInPictureController object.
    private var pictureInPictureController: AVPictureInPictureController? {
        didSet { didUpdate(pictureInPictureController) }
    }

    /// The StreamAVPictureInPictureViewControlling object that manages the picture-in-picture view.
    private var contentViewController: StreamAVPictureInPictureVideoCallViewController?

    /// A set of `AnyCancellable` objects used to manage subscriptions.
    private var disposableBag = DisposableBag()

    // MARK: - Lifecycle

    /// Initializes the controller and creates the content view
    ///
    /// - Parameter canStartPictureInPictureAutomaticallyFromInline A boolean value
    /// indicating whether the picture-in-picture session should start automatically when the app enters
    /// background.
    ///
    /// - Returns `nil` if AVPictureInPictureController is not supported, or the controller otherwise.
    @MainActor
    init?(
        store: PictureInPictureStore
    ) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return nil
        }

        self.store = store

        store
            .publisher(for: \.sourceView)
            .removeDuplicates()
            .sinkTask { @MainActor [weak self] in self?.didUpdate($0) }
            .store(in: disposableBag)

        // We add a small delay (250ms) on cancelling PiP as if we do it too early it
        // seems that it has no effect.
        // Calling `stopPictureInPicture` is a safe operation as it will only
        // stop it if it is active.
        applicationStateAdapter
            .$state
            .filter { $0 == .foreground }
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.pictureInPictureController?.stopPictureInPicture() }
            .store(in: disposableBag)
    }

    @MainActor
    private func didUpdate(_ sourceView: UIView?) {
        guard let sourceView else {
            pictureInPictureController?.contentSource = nil
            pictureInPictureController = nil
            disposableBag.remove(DisposableKey.isPossible.rawValue)
            disposableBag.remove(DisposableKey.isActive.rawValue)
            return
        }

        if contentViewController == nil {
            let contentViewController = StreamAVPictureInPictureVideoCallViewController(
                store: store
            )
            self.contentViewController = contentViewController
        }

        guard let contentViewController else {
            return
        }

        pictureInPictureController = .init(
            contentSource: .init(
                activeVideoCallSourceView: sourceView,
                contentViewController: contentViewController
            )
        )
        pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = store.state
            .canStartPictureInPictureAutomaticallyFromInline
        pictureInPictureController?.delegate = proxyDelegate
    }

    @MainActor
    private func didUpdate(_ viewFactory: AnyViewFactory) {
        contentViewController = StreamAVPictureInPictureVideoCallViewController(
            store: store
        )

        didUpdate(store.state.sourceView)
    }

    private func didUpdate(_ pictureInPictureController: AVPictureInPictureController?) {
        if let pictureInPictureController {
            pictureInPictureController
                .publisher(for: \.isPictureInPicturePossible)
                .removeDuplicates()
                .log(.debug, subsystems: .pictureInPicture) { "isPossible:\($0)" }
                .sink { _ in }
                .store(in: disposableBag, key: DisposableKey.isPossible.rawValue)

            pictureInPictureController
                .publisher(for: \.isPictureInPictureActive)
                .removeDuplicates()
                .log(.debug, subsystems: .pictureInPicture) { "isActive:\($0)" }
                .sink { [weak self] in self?.store.dispatch(.setActive($0)) }
                .store(in: disposableBag, key: DisposableKey.isActive.rawValue)

            log.debug("Controller has been configured.", subsystems: .pictureInPicture)
        } else {
            disposableBag.remove(DisposableKey.isPossible.rawValue)
            disposableBag.remove(DisposableKey.isActive.rawValue)
            log.debug("Controller has been released.", subsystems: .pictureInPicture)
        }
    }
}
