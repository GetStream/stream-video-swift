//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC
import AVKit
import MetalKit
import StreamVideo

class PiPHandler: NSObject {
            
    private(set) var pictureInPictureActive = false
    var sampleBufferVideoCallView: SampleBufferVideoCallView?
    var pipController: AVPictureInPictureController?
    
    private var sourceView: VideoRenderer?
        
    func setupPictureInPicture(with sourceView: VideoRenderer?) {
        guard (self.sourceView == nil
               || sourceView?.trackId != self.sourceView?.trackId) else {
            return
        }
        if self.sourceView != nil {
            cleanUp()
        }
        self.sourceView = sourceView
        if #available(iOS 15.0, *) {
            setupPictureInPicture()
        }
    }
    
    func startPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }
        pictureInPictureActive = true
        if #available(iOS 15.0, *) {
            if pipController?.isPictureInPicturePossible == true {
                pipController?.startPictureInPicture()
            }
        }
    }
    
    func feedBuffer(_ buffer: CMSampleBuffer) {
        guard pictureInPictureActive else {
            return
        }
        DispatchQueue.main.async {
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
        DispatchQueue.main.async {
            let sampleBufferVideoCallView = SampleBufferVideoCallView()
            sampleBufferVideoCallView.contentMode = .scaleAspectFit
            sampleBufferVideoCallView.sampleBufferDisplayLayer.videoGravity = .resizeAspect

            let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
            //TODO: don't hardcode content size.
            pipVideoCallViewController.preferredContentSize = CGSize(width: 1280, height: 720)
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
            
            view.feedFrames = { buffer in
                self.feedBuffer(buffer)
            }
                    
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
