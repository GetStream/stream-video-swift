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
    
    var sourceView: VideoRenderer?
    
    private let pipRenderer = PiPRenderer()
    
    init(sourceView: VideoRenderer?) {
        super.init()
        self.sourceView = sourceView
        if #available(iOS 15.0, *) {
            setupPictureInPicture()
        }
    }
    
    func test() {
        print("====== test")
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
    
    @available(iOS 15.0, *)
    func setupPictureInPicture() {
        guard let view = self.sourceView else { return }
        DispatchQueue.main.async {
            let sampleBufferVideoCallView = SampleBufferVideoCallView()
            sampleBufferVideoCallView.contentMode = .scaleAspectFit
            sampleBufferVideoCallView.sampleBufferDisplayLayer.videoGravity = .resizeAspect

            let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
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
            
            self.pipRenderer.feedFrames = { buffer in
                self.feedBuffer(buffer)
            }
            view.track?.add(self.pipRenderer)
            
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
    
    func stopPiP() {
        pictureInPictureActive = false
        pipController?.stopPictureInPicture()
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
