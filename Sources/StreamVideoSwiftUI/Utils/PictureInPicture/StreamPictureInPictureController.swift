//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import AVKit
import StreamWebRTC
import StreamVideo
import Combine

final class StreamPictureInPictureController: NSObject, AVPictureInPictureControllerDelegate {

    var track: RTCVideoTrack? {
        didSet {
            didUpdate(track)
        }
    }

    var sourceView: UIView? {
        didSet {
            guard sourceView !== oldValue else { return }
            didUpdate(sourceView)
        }
    }

    var onSizeUpdate: ((CGSize) -> Void)? {
        didSet { contentViewController.onSizeUpdate = onSizeUpdate }
    }

    let canStartPictureInPictureAutomaticallyFromInline: Bool

    private var pictureInPictureController: AVPictureInPictureController?
    private var contentViewController: StreamAVPictureInPictureViewControlling
    private var cancellableBag: Set<AnyCancellable> = .init()
    private var ensureActiveTrackIsEnabledCancellable: AnyCancellable?
    private let trackStateAdapter: StreamPictureInPictureTrackStateAdapter = .init()

    init?(canStartPictureInPictureAutomaticallyFromInline: Bool = true) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return nil
        }

        var contentViewController: StreamAVPictureInPictureViewControlling = {
            if #available(iOS 15.0, *) {
                return StreamAVPictureInPictureVideoCallViewController()
            } else {
                return StreamAVPictureInPictureViewController()
            }
        }()
        contentViewController.preferredContentSize = .init(width: 640, height: 480)
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
        contentViewController.track = track
        trackStateAdapter.activeTrack = track
    }

    private func didUpdate(_ sourceView: UIView?) {
        if let sourceView {
            if pictureInPictureController?.isPictureInPictureActive != false {
                makePictureInPictureController(with: sourceView)

                pictureInPictureController?
                    .publisher(for: \.isPictureInPicturePossible)
                    .removeDuplicates()
                    .sink { log.debug("isPictureInPicturePossible:\($0)") }
                    .store(in: &cancellableBag)

                pictureInPictureController?
                    .publisher(for: \.isPictureInPictureActive)
                    .removeDuplicates()
                    .sink { [weak self] in self?.didUpdatePictureInPictureActiveState($0)  }
                    .store(in: &cancellableBag)
            } else {
                if #available(iOS 15.0, *), let contentViewController = contentViewController as? StreamAVPictureInPictureVideoCallViewController {
                    pictureInPictureController?.contentSource = .init(
                        activeVideoCallSourceView: sourceView,
                        contentViewController: contentViewController
                    )
                }
            }
        } else {
            if #available(iOS 15.0, *) {
                pictureInPictureController?.contentSource = nil
            }
        }
    }

    private func makePictureInPictureController(with sourceView: UIView) {
        if #available(iOS 15.0, *), let contentViewController = contentViewController as? StreamAVPictureInPictureVideoCallViewController {
            pictureInPictureController = .init(
                contentSource: .init(
                    activeVideoCallSourceView: sourceView,
                    contentViewController: contentViewController
                ))
        } else {
            pictureInPictureController = .init(playerLayer: .init(layer: contentViewController.displayLayer))
        }

        if #available(iOS 14.2, *) {
            pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline
        }

        pictureInPictureController?.delegate = self
    }

    private func didUpdatePictureInPictureActiveState(_ isActive: Bool) {
        log.debug("isPictureInPictureActive:\(isActive)")
        trackStateAdapter.isEnabled = isActive
    }
}
