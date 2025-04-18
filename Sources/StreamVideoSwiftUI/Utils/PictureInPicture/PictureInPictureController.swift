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

/// Controls the Picture-in-Picture functionality for video calls.
///
/// This controller manages the Picture-in-Picture window state and handles transitions
/// between foreground and background states.
@available(iOS 15.0, *)
final class PictureInPictureController: @unchecked Sendable {

    private enum DisposableKey: String { case isPossible, isActive }

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    // MARK: - Properties

    private let store: PictureInPictureStore

    private let proxyDelegate: PictureInPictureDelegateProxy = .init()

    private var didAppBecomeActiveCancellable: AnyCancellable?

    // MARK: - Private Properties

    /// The system Picture-in-Picture controller instance.
    private var pictureInPictureController: AVPictureInPictureController? {
        didSet { didUpdate(pictureInPictureController) }
    }

    /// The view controller managing Picture-in-Picture content.
    private var contentViewController: PictureInPictureVideoCallViewController?

    /// Collection of active subscriptions.
    private var disposableBag = DisposableBag()

    // MARK: - Lifecycle

    /// Creates a new Picture-in-Picture controller.
    ///
    /// - Parameter store: The store managing Picture-in-Picture state
    /// - Returns: `nil` if Picture-in-Picture is not supported on the device
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

        // Add delay to prevent premature cancellation
        applicationStateAdapter
            .$state
            .filter { $0 == .foreground }
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.pictureInPictureController?.stopPictureInPicture() }
            .store(in: disposableBag)
    }

    /// Updates the Picture-in-Picture controller when the source view changes.
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
            let contentViewController = PictureInPictureVideoCallViewController(
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

    /// Updates the content view controller when the view factory changes.
    @MainActor
    private func didUpdate(_ viewFactory: AnyViewFactory) {
        contentViewController = PictureInPictureVideoCallViewController(
            store: store
        )

        didUpdate(store.state.sourceView)
    }

    /// Handles updates to the Picture-in-Picture controller state.
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
