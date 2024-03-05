//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import Foundation
import StreamVideo
import StreamWebRTC

/// A controller class for picture-in-picture whenever that is possible.
final class StreamPictureInPictureController: NSObject, AVPictureInPictureControllerDelegate {

    // MARK: - Properties

    /// The RTCVideoTrack for which the picture-in-picture session is created.
    public var track: RTCVideoTrack? {
        didSet {
            didUpdate(track) // Called when the `track` property changes
        }
    }

    /// The UIView that contains the video content.
    public var sourceView: UIView? {
        didSet {
            didUpdate(sourceView) // Called when the `sourceView` property changes
        }
    }

    /// A closure called when the picture-in-picture view's size changes.
    public var onSizeUpdate: ((CGSize) -> Void)? {
        didSet {
            contentViewController?.onSizeUpdate = onSizeUpdate // Updates the onSizeUpdate closure of the content view controller
        }
    }

    /// A boolean value indicating whether the picture-in-picture session should start automatically when the app enters background.
    public var canStartPictureInPictureAutomaticallyFromInline: Bool

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

        var contentViewController: StreamAVPictureInPictureViewControlling? = {
            if #available(iOS 15.0, *) {
                return StreamAVPictureInPictureVideoCallViewController()
            } else {
                return nil
            }
        }()
        contentViewController?.preferredContentSize = .init(width: 640, height: 480)
        self.contentViewController = contentViewController
        self.canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline
        super.init()
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }

    public func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        log.debug("Will start with trackId:\(track?.trackId ?? "n/a")")
    }

    public func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        log.debug("Did start with trackId:\(track?.trackId ?? "n/a")")
    }

    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        log.error("Failed for trackId:\(track?.trackId ?? "na/a") with error:\(error)")
    }

    public func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        log.debug("Will stop for trackId:\(track?.trackId ?? "n/a")")
    }

    public func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        log.debug("Did stop for trackId:\(track?.trackId ?? "n/a")")
    }

    // MARK: - Private helpers

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
                    .sink { log.debug("isPictureInPicturePossible:\($0)") }
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
        log.debug("isPictureInPictureActive:\(isActive)")
        trackStateAdapter.isEnabled = isActive
    }
}
