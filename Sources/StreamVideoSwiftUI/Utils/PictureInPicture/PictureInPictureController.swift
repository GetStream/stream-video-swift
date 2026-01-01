//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    /// Adapter responsible for enforcing the stop of Picture in Picture when
    /// the application returns to the foreground. It monitors app state and
    /// PiP activity to ensure PiP is stopped when appropriate.
    private var enforcedStopAdapter: PictureInPictureEnforcedStopAdapter?

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
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.didUpdate($0) }
            .store(in: disposableBag)

        proxyDelegate
            .publisher
            .compactMap {
                switch $0 {
                case let .failedToStart(_, error):
                    return error
                default:
                    return nil
                }
            }
            .log(.error, subsystems: .pictureInPicture) { "Picture-in-Picture failed to start: \($0)." }
            .sink { _ in }
            .store(in: disposableBag)
    }

    /// Updates the Picture-in-Picture controller when the source view changes.
    @MainActor
    private func didUpdate(_ sourceView: UIView?) {
        guard let sourceView, store.state.call != nil else {
            /// We ensure to cleanUp every Picture-in-Picture interacting component so that the next
            /// Call will start with clean state.
            pictureInPictureController?.stopPictureInPicture()
            pictureInPictureController?.contentSource = nil
            contentViewController = nil
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
        let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: sourceView,
            contentViewController: contentViewController
        )

        if pictureInPictureController == nil {
            pictureInPictureController = .init(
                contentSource: contentSource
            )
            pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = store
                .state
                .canStartPictureInPictureAutomaticallyFromInline
            pictureInPictureController?.delegate = proxyDelegate
        } else {
            pictureInPictureController?.contentSource = contentSource
        }

        log.debug(
            "SourceView updated and contentViewController preferredContentSize:\(contentViewController.preferredContentSize)",
            subsystems: .pictureInPicture
        )
    }

    /// Updates the content view controller when the view factory changes.
    @MainActor
    private func didUpdate(_ viewFactory: PictureInPictureViewFactory) {
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

            enforcedStopAdapter = .init(pictureInPictureController)

            log.debug("Controller has been configured.", subsystems: .pictureInPicture)
        } else {
            enforcedStopAdapter = nil
            disposableBag.remove(DisposableKey.isPossible.rawValue)
            disposableBag.remove(DisposableKey.isActive.rawValue)
            log.debug("Controller has been released.", subsystems: .pictureInPicture)
        }
    }
}
