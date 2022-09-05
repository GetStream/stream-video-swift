//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

class VideoCapturer {
    
    private var videoCapturer: RTCCameraVideoCapturer
    
    init(videoSource: RTCVideoSource) {
        #if targetEnvironment(simulator)
        videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
    }
    
    func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) {
        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == cameraPosition }),
            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last,
        
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { $0.maxFrameRate < $1.maxFrameRate }.last) else {
            return
        }

        videoCapturer.startCapture(
            with: frontCamera,
            format: format,
            fps: Int(fps.maxFrameRate)
        )
    }
}
