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
    private let makePictureInPictureController: @MainActor (
        AVPictureInPictureController.ContentSource
    ) -> AVPictureInPictureController

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
    /// - Parameter isPictureInPictureSupported: Whether the device supports
    ///   Picture-in-Picture.
    /// - Parameter makePictureInPictureController: Creates the system
    ///   Picture-in-Picture controller.
    /// - Returns: `nil` if Picture-in-Picture is not supported on the device
    @MainActor
    init?(
        store: PictureInPictureStore,
        isPictureInPictureSupported: Bool = AVPictureInPictureController
            .isPictureInPictureSupported(),
        makePictureInPictureController: @escaping @MainActor (
            AVPictureInPictureController.ContentSource
        ) -> AVPictureInPictureController = {
            AVPictureInPictureController(contentSource: $0)
        }
    ) {
        guard isPictureInPictureSupported else {
            log.warning(
                "Picture-in-Picture isn't supported on this device.",
                subsystems: .pictureInPicture
            )
            return nil
        }

        self.store = store
        self.makePictureInPictureController = makePictureInPictureController

        Publishers.CombineLatest4(
            store
                .publisher(for: \.call)
                .removeDuplicates { $0?.cId == $1?.cId },
            store.publisher(for: \.sourceView).removeDuplicates(),
            // Only the identity travels through the sink, because the layer
            // isn't `Sendable`.
            store
                .publisher(for: \.playerLayer)
                .map { $0.map(ObjectIdentifier.init) }
                .removeDuplicates(),
            store.publisher(for: \.playerLayerCallId).removeDuplicates()
        )
        // Each value runs in its own task, so a stale value can run last.
        // The latest state makes every run end in the same result.
        .sinkTask(storeIn: disposableBag) { @MainActor [weak self] _, _, _, _ in
            guard let self else { return }
            didUpdate(call: store.state.call, sourceView: store.state.sourceView)
        }
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

    /// Updates the Picture-in-Picture controller when the call, source view
    /// or HLS player layer changes.
    @MainActor
    private func didUpdate(call: Call?, sourceView: UIView?) {
        guard let call, let sourceView else {
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
        // Force view loading once PiP infrastructure is ready, so SwiftUI can
        // instantiate the renderer early and receive track size callbacks
        // before the first PiP activation.
        contentViewController.loadViewIfNeeded()

        // The system shows the player layer of the HLS renderer.
        var hlsPlayerLayer: AVPlayerLayer?
        if
            case .hls = call.state.playbackType,
            store.state.playerLayerCallId == call.cId {
            hlsPlayerLayer = store.state.playerLayer
        }
        let contentSource = hlsPlayerLayer.map {
            AVPictureInPictureController.ContentSource(playerLayer: $0)
        } ?? AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: sourceView,
            contentViewController: contentViewController
        )

        if pictureInPictureController == nil {
            pictureInPictureController = makePictureInPictureController(contentSource)
            pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = store
                .state
                .canStartPictureInPictureAutomaticallyFromInline
            pictureInPictureController?.delegate = proxyDelegate
        } else {
            pictureInPictureController?.contentSource = contentSource
        }
        // A livestream has no seeking in the Picture-in-Picture window.
        pictureInPictureController?.requiresLinearPlayback = hlsPlayerLayer != nil

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

        didUpdate(call: store.state.call, sourceView: store.state.sourceView)
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
