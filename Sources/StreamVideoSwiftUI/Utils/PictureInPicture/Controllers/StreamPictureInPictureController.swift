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
final class StreamPictureInPictureController: NSObject, @unchecked Sendable {

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    // MARK: - Properties

    @Published private(set) var isPossible: Bool = false
    @Published private(set) var isActive: Bool = false

    /// The UIView that contains the video content.
    var sourceView: UIView? {
        didSet { didUpdate(sourceView) }
    }

    /// A boolean value indicating whether the picture-in-picture session should start automatically when the app enters background.
    var canStartPictureInPictureAutomaticallyFromInline: Bool

    private var didAppBecomeActiveCancellable: AnyCancellable?

    // MARK: - Private Properties

    /// The AVPictureInPictureController object.
    private var pictureInPictureController: AVPictureInPictureController?
    private lazy var pictureInPictureDelegate: StreamPictureInPictureDelegateProxy = .init()

    /// The StreamAVPictureInPictureViewControlling object that manages the picture-in-picture view.
    private var contentViewController: StreamAVPictureInPictureViewControlling?

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
    init?(
        dataPipeline: PictureInPictureDataPipeline,
        canStartPictureInPictureAutomaticallyFromInline: Bool = true
    ) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return nil
        }

        self.canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline

        super.init()

        Task { @MainActor in
            guard #available(iOS 15.0, *) else {
                return
            }
            let contentViewController = StreamAVPictureInPictureVideoCallViewController(
                dataPipeline: dataPipeline
            )
            self.contentViewController = contentViewController
        }
    }

    // MARK: - Private helpers

    private func didUpdate(_ sourceView: UIView?) {
        guard #available(iOS 15.0, *), sourceView !== pictureInPictureController?.contentSource?.activeVideoCallSourceView else {
            return
        }

        if let sourceView, let contentViewController = contentViewController as? AVPictureInPictureVideoCallViewController {
            buildPictureInPictureController(sourceView: sourceView, contentViewController: contentViewController)
            Task { @MainActor in
                log.debug(
                    """
                    SourceView updated and new view hasWindow:\(sourceView.window != nil) size:\(sourceView.bounds.size).
                    """,
                    subsystems: .pictureInPicture
                )
            }
        } else {
            pictureInPictureController?.contentSource = nil
        }
    }

    private func subscribeToPictureInPictureState() {
        pictureInPictureController?
            .publisher(for: \.isPictureInPicturePossible)
            .removeDuplicates()
            .log(.debug, subsystems: .pictureInPicture) { "Picture-in-Picture isPossible:\($0)" }
            .assign(to: \.isPossible, onWeak: self)
            .store(in: disposableBag, key: "isPictureInPicturePossible")

        pictureInPictureController?
            .publisher(for: \.isPictureInPictureActive)
            .removeDuplicates()
            .log(.debug, subsystems: .pictureInPicture) { "Picture-in-Picture isActive:\($0)" }
            .assign(to: \.isActive, onWeak: self)
            .store(in: disposableBag, key: "isPictureInPictureActive")
    }

    private func subscribeToPictureInPictureControllerDelegate() {
        pictureInPictureDelegate
            .publisher
            .log(.debug, subsystems: .pictureInPicture) { "\($0)" }
            .sink { _ in }
            .store(in: disposableBag)

        pictureInPictureDelegate
            .publisher
            .compactMap {
                switch $0 {
                case let .restoreUI(controller, completion):
                    return (controller, completion)
                default:
                    return nil
                }
            }
            .sink { (_: AVPictureInPictureController, completion: @escaping (Bool) -> Void) in
                completion(true)
            }
            .store(in: disposableBag)
    }

    private func subscribeToApplicationStateNotifications() {
        // We add a small delay (250ms) on cancelling PiP as if we do it too early it
        // seems that it has no effect.
        // Calling `stopPictureInPicture` is a safe operation as it will only
        // stop it if it is active.
        didAppBecomeActiveCancellable = applicationStateAdapter
            .$state
            .filter { $0 == .foreground }
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.pictureInPictureController?.stopPictureInPicture() }
    }

    @available(iOS 15.0, *)
    private func buildPictureInPictureController(
        sourceView: UIView,
        contentViewController: AVPictureInPictureVideoCallViewController
    ) {
        disposableBag.removeAll()

        let pictureInPictureController = AVPictureInPictureController(
            contentSource: .init(
                activeVideoCallSourceView: sourceView,
                contentViewController: contentViewController
            )
        )
        pictureInPictureController.delegate = pictureInPictureDelegate
        pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline
        self.pictureInPictureController = pictureInPictureController

        subscribeToPictureInPictureState()
        subscribeToPictureInPictureControllerDelegate()
        subscribeToApplicationStateNotifications()
    }
}
