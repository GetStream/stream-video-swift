//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import AVKit
import StreamWebRTC
import StreamVideo
import Combine

@available(iOS 15.0, *)
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
    private let contentViewController: StreamAVPictureInPictureVideoCallViewController
    private var cancellableBag: Set<AnyCancellable> = .init()
    private var ensureActiveTrackIsEnabledCancellable: AnyCancellable?
    private let trackStateAdapter: StreamPictureInPictureTrackStateAdapter = .init()

    init?(canStartPictureInPictureAutomaticallyFromInline: Bool = true) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return nil
        }

        let contentViewController = StreamAVPictureInPictureVideoCallViewController()
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

    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        log.debug("picture in picture will start called")
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        log.debug("picture in picture did start called with track:\(track?.trackId)")
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        log.debug("picture in picture failed to start called \(error)")
    }

    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        log.debug("picture in picture will stop called")
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        log.debug("picture in picture did stop called")
    }

    // MARK: - Private helpers

    private func didUpdate(_ track: RTCVideoTrack?) {
        contentViewController.track = track
        trackStateAdapter.activeTrack = track
    }

    private func didUpdate(_ sourceView: UIView?) {
        if let sourceView {
            if pictureInPictureController?.isPictureInPictureActive != false {
                pictureInPictureController = .init(
                    contentSource: .init(
                        activeVideoCallSourceView: sourceView,
                        contentViewController: contentViewController
                    ))
                pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline
                pictureInPictureController?.delegate = self

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
                pictureInPictureController?.contentSource = .init(
                    activeVideoCallSourceView: sourceView,
                    contentViewController: contentViewController
                )
            }
        } else {
            pictureInPictureController?.contentSource = nil
        }
    }

    private func didUpdatePictureInPictureActiveState(_ isActive: Bool) {
        log.debug("isPictureInPictureActive:\(isActive)")
        trackStateAdapter.isEnabled = isActive
    }
}
