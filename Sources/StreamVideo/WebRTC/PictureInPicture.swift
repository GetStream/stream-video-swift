//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVKit
import Foundation
import WebRTC

class PictureInPictureHandler: NSObject, RTCVideoCapturerDelegate, AVPictureInPictureControllerDelegate {
    
    let source: RTCVideoSource
    var sampleBufferVideoCallView: SampleBufferVideoCallView?
    var pipController: AVPictureInPictureController?
    
    init(source: RTCVideoSource) {
        self.source = source
        super.init()
        if #available(iOS 15.0, *) {
            setupPictureInPicture()
        }
    }
    
    @available(iOS 15.0, *)
    func setupPictureInPicture() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }
        DispatchQueue.main.async {
            let sampleBufferVideoCallView = SampleBufferVideoCallView()
            let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
            pipVideoCallViewController.preferredContentSize = CGSize(width: 640, height: 480)
            pipVideoCallViewController.view.addSubview(sampleBufferVideoCallView)
            let pipContentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: sampleBufferVideoCallView,
                contentViewController: pipVideoCallViewController
            )
            self.sampleBufferVideoCallView = sampleBufferVideoCallView
            let pipController = AVPictureInPictureController(contentSource: pipContentSource)
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            pipController.delegate = self
            self.pipController = pipController
        }
    }
    
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        guard let buffer: RTCCVPixelBuffer = frame.buffer as? RTCCVPixelBuffer else {
            source.capturer(capturer, didCapture: frame)
            return
        }
        let imageBuffer = buffer.pixelBuffer
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        if let sampleBuffer = createSampleBufferFrom(pixelBuffer: imageBuffer) {
            DispatchQueue.main.async {
                self.sampleBufferVideoCallView?.sampleBufferDisplayLayer.enqueue(sampleBuffer)
            }
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        source.capturer(capturer, didCapture: frame)
    }
    
    func createSampleBufferFrom(pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        
        var timimgInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        _ = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription!,
            sampleTiming: &timimgInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        return sampleBuffer
    }
}

class SampleBufferVideoCallView: UIView {
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }
    
    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }
}

class PictureInPictureCapturer: RTCCameraVideoCapturer {
    
    override init(delegate: RTCVideoCapturerDelegate) {
        super.init(delegate: delegate)
        setupPiP()
    }
    
    func setupPiP() {
        captureSession.beginConfiguration()
        if #available(iOS 16, *),
           captureSession.isMultitaskingCameraAccessSupported,
           AVPictureInPictureController.isPictureInPictureSupported() {
            DispatchQueue.main.async {
                self.captureSession.isMultitaskingCameraAccessEnabled = true
            }
        }
        captureSession.commitConfiguration()
    }
}
