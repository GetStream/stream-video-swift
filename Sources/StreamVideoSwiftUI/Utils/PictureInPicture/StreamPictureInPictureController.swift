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
final class StreamPictureInPictureController: NSObject, AVPictureInPictureControllerDelegate, @unchecked Sendable {

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    // MARK: - Properties

    var preferredContentSize: CGSize = .init(width: 640, height: 480) {
        didSet {
            Task { @MainActor in
                contentViewController?.preferredContentSize = preferredContentSize
            }
        }
    }

    /// The RTCVideoTrack for which the picture-in-picture session is created.
    @MainActor
    var track: RTCVideoTrack? {
        didSet {
            didUpdate(track) // Called when the `track` property changes
        }
    }

    /// The UIView that contains the video content.
    var sourceView: UIView? {
        didSet {
            didUpdate(sourceView) // Called when the `sourceView` property changes
        }
    }

    /// A closure called when the picture-in-picture view's size changes.
    @MainActor
    var onSizeUpdate: (@Sendable(CGSize) -> Void)? {
        didSet {
            contentViewController?.onSizeUpdate = onSizeUpdate // Updates the onSizeUpdate closure of the content view controller
        }
    }

    /// A boolean value indicating whether the picture-in-picture session should start automatically when the app enters background.
    var canStartPictureInPictureAutomaticallyFromInline: Bool

    private var didAppBecomeActiveCancellable: AnyCancellable?

    // MARK: - Private Properties

    /// The AVPictureInPictureController object.
    private var pictureInPictureController: AVPictureInPictureController?

    /// The StreamAVPictureInPictureViewControlling object that manages the picture-in-picture view.
    private var contentViewController: StreamAVPictureInPictureViewControlling?

    /// A set of `AnyCancellable` objects used to manage subscriptions.
    private var cancellableBag: Set<AnyCancellable> = []

    /// A `AnyCancellable` object used to ensure that the active track is enabled while in picture-in-picture
    /// mode.
    private var ensureActiveTrackIsEnabledCancellable: AnyCancellable?

    /// A `StreamPictureInPictureTrackStateAdapter` object that manages the state of the
    /// active track.
    private let trackStateAdapter: StreamPictureInPictureTrackStateAdapter = .init()

    // MARK: - Lifecycle

    /// Initializes the controller and creates the content view
    ///
    /// - Parameter canStartPictureInPictureAutomaticallyFromInline A boolean value
    /// indicating whether the picture-in-picture session should start automatically when the app enters
    /// background.
    ///
    /// - Returns `nil` if AVPictureInPictureController is not supported, or the controller otherwise.
    init?(canStartPictureInPictureAutomaticallyFromInline: Bool = true) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return nil
        }

        self.canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline

        super.init()

        Task { @MainActor in
            let contentViewController: StreamAVPictureInPictureViewControlling? = {
                if #available(iOS 15.0, *) {
                    return StreamAVPictureInPictureVideoCallViewController()
                } else {
                    return nil
                }
            }()
            self.contentViewController = contentViewController

            subscribeToApplicationStateNotifications()
        }
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        Task { @MainActor in
            log.debug("Will start with trackId:\(track?.trackId ?? "n/a")", subsystems: .pictureInPicture)
        }
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        Task { @MainActor in
            log.debug("Did start with trackId:\(track?.trackId ?? "n/a")", subsystems: .pictureInPicture)
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Task { @MainActor in
            log.error("Failed for trackId:\(track?.trackId ?? "na/a") with error:\(error)", subsystems: .pictureInPicture)
        }
    }

    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        Task { @MainActor in
            log.debug("Will stop for trackId:\(track?.trackId ?? "n/a")", subsystems: .pictureInPicture)
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        Task { @MainActor in
            log.debug("Did stop for trackId:\(track?.trackId ?? "n/a")", subsystems: .pictureInPicture)
        }
    }

    // MARK: - Private helpers

    @MainActor
    private func didUpdate(_ track: RTCVideoTrack?) {
        contentViewController?.track = track
        trackStateAdapter.activeTrack = track
    }

    private func didUpdate(_ sourceView: UIView?) {
        if let sourceView {
            // If picture-in-picture isn't active, just create a new controller.
            if pictureInPictureController?.isPictureInPictureActive != true {
                makePictureInPictureController(with: sourceView)

                pictureInPictureController?
                    .publisher(for: \.isPictureInPicturePossible)
                    .removeDuplicates()
                    .sink { log.debug("isPictureInPicturePossible:\($0)", subsystems: .pictureInPicture) }
                    .store(in: &cancellableBag)

                pictureInPictureController?
                    .publisher(for: \.isPictureInPictureActive)
                    .removeDuplicates()
                    .sink { [weak self] in self?.didUpdatePictureInPictureActiveState($0) }
                    .store(in: &cancellableBag)
            } else {
                // If picture-in-picture is active, simply update the sourceView.
                makePictureInPictureController(with: sourceView)
            }
        } else {
            if #available(iOS 15.0, *) {
                pictureInPictureController?.contentSource = nil
            }
            pictureInPictureController = nil
            cancellableBag.removeAll()
        }
    }

    private func makePictureInPictureController(with sourceView: UIView) {
        if #available(iOS 15.0, *),
           let contentViewController = contentViewController as? StreamAVPictureInPictureVideoCallViewController {
            pictureInPictureController = .init(
                contentSource: .init(
                    activeVideoCallSourceView: sourceView,
                    contentViewController: contentViewController
                )
            )
        }

        if #available(iOS 14.2, *) {
            pictureInPictureController?
                .canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline
        }

        pictureInPictureController?.delegate = self
    }

    private func didUpdatePictureInPictureActiveState(_ isActive: Bool) {
        log.debug("isPictureInPictureActive:\(isActive)", subsystems: .pictureInPicture)
        trackStateAdapter.isEnabled = isActive
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
}
