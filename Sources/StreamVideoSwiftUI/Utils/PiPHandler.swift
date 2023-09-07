//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC
import AVKit
import MetalKit
import StreamVideo

final class PiPHandler: NSObject {
            
    private(set) var pictureInPictureActive = false
    var sampleBufferVideoCallView: SampleBufferVideoCallView?
    var pipController: AVPictureInPictureController?
    
    private var sourceView: VideoRenderer?
        
    func setupPictureInPicture(with sourceView: VideoRenderer?) {
        if #available(iOS 15.0, *) {
            guard (self.sourceView == nil
                   || sourceView?.trackId != self.sourceView?.trackId) else {
                return
            }
            if self.sourceView != nil {
                cleanUp()
            }
            self.sourceView = sourceView
            setupPictureInPicture()
        }
    }
    
    func startPiP() {
        if #available(iOS 15.0, *) {
            guard AVPictureInPictureController.isPictureInPictureSupported() else {
                return
            }
            pictureInPictureActive = true
            if pipController?.isPictureInPicturePossible == true {
                sourceView?.feedFrames = { buffer in
                    self.feedBuffer(buffer)
                }
                pipController?.startPictureInPicture()
            }
        }
    }
    
    func feedBuffer(_ buffer: CMSampleBuffer) {
        guard pictureInPictureActive else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let layer = self.sampleBufferVideoCallView?.sampleBufferDisplayLayer
            if #available(iOS 14.0, *) {
                if layer?.requiresFlushToResumeDecoding == true {
                    layer?.flush()
                }
            }
            if layer?.isReadyForMoreMediaData == true {
                layer?.enqueue(buffer)
            }
        }
    }
    
    func stopPiP() {
        cleanUp()
    }
    
    func addObservers() {
        // Observe when the system interrupts the capture session.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruptionStarted),
            name: .AVCaptureSessionWasInterrupted,
            object: nil
        )

    }
    
    @objc func handleInterruptionStarted(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int,
              let reason = AVCaptureSession.InterruptionReason(rawValue: reasonValue) else {
            log.error("Failed to parse the interruption reason.")
            return
        }


        switch reason {
        case .videoDeviceNotAvailableInBackground:
            log.warning("Camera not available in background")
        case .videoDeviceNotAvailableWithMultipleForegroundApps:
            log.warning("Camera not available for multiple foreground apps")
        case .videoDeviceNotAvailableDueToSystemPressure:
            log.warning("Camera interrupted because of increasing system pressure")
        default:
            log.warning("Camera interrupted because of \(reason)")
        }
    }
    
    @available(iOS 15.0, *)
    private func setupPictureInPicture() {
        guard let view = self.sourceView else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let sampleBufferVideoCallView = SampleBufferVideoCallView()
            sampleBufferVideoCallView.contentMode = .scaleAspectFit
            sampleBufferVideoCallView.sampleBufferDisplayLayer.videoGravity = .resizeAspect

            let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
            pipVideoCallViewController.preferredContentSize = self.preferredPiPContentSize()
            pipVideoCallViewController.view.addSubview(sampleBufferVideoCallView)
            
            sampleBufferVideoCallView.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                sampleBufferVideoCallView.leadingAnchor.constraint(equalTo: pipVideoCallViewController.view.leadingAnchor),
                sampleBufferVideoCallView.trailingAnchor.constraint(equalTo: pipVideoCallViewController.view.trailingAnchor),
                sampleBufferVideoCallView.topAnchor.constraint(equalTo: pipVideoCallViewController.view.topAnchor),
                sampleBufferVideoCallView.bottomAnchor.constraint(equalTo: pipVideoCallViewController.view.bottomAnchor)
            ]
            NSLayoutConstraint.activate(constraints)

            sampleBufferVideoCallView.bounds = pipVideoCallViewController.view.frame
            self.sampleBufferVideoCallView = sampleBufferVideoCallView
                    
            let pipContentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: view,
                contentViewController: pipVideoCallViewController
            )
            
            let pipController = AVPictureInPictureController(contentSource: pipContentSource)
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            pipController.delegate = self
            
            self.pipController = pipController
                
            self.addObservers()
        }
    }
    
    private func preferredPiPContentSize() -> CGSize {
        let width = 640
        let height = 480
        let orientation = UIDevice.current.orientation
        if orientation.isPortrait {
            return CGSize(width: height, height: width)
        } else {
            return CGSize(width: width, height: height)
        }
    }
    
    private func cleanUp() {
        sourceView?.feedFrames = nil
        sourceView = nil
        sampleBufferVideoCallView?.sampleBufferDisplayLayer.flushAndRemoveImage()
        sampleBufferVideoCallView?.removeFromSuperview()
        sampleBufferVideoCallView = nil
        pictureInPictureActive = false
        pipController?.stopPictureInPicture()
        if #available(iOS 15.0, *) {
            pipController?.contentSource = nil
        }
        pipController = nil
    }
}

extension PiPHandler: AVPictureInPictureControllerDelegate {
    
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        log.debug("picture in picture will start called")
    }
    
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        log.debug("picture in picture did start called")
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
}
