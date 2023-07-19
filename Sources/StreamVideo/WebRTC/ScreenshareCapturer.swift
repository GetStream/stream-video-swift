//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC
#if canImport(ReplayKit)
import ReplayKit
#endif

class ScreenshareCapturer {
    private var videoCapturer: RTCVideoCapturer
    private var videoOptions: VideoOptions
    private let videoSource: RTCVideoSource
    private var videoCaptureHandler: StreamVideoCaptureHandler?
    
    init(
        videoSource: RTCVideoSource,
        videoOptions: VideoOptions,
        videoFilters: [VideoFilter]
    ) {
        self.videoOptions = videoOptions
        self.videoSource = videoSource
        #if targetEnvironment(simulator)
        videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        let handler = StreamVideoCaptureHandler(source: videoSource, filters: videoFilters, handleRotation: false)
        videoCaptureHandler = handler
        videoCapturer = RTCCameraVideoCapturer(delegate: handler)
        #endif
    }
    
    func startCapture() {
        let devices = RTCCameraVideoCapturer.captureDevices()
        
        guard let device = devices.first else {
            log.warning("No camera video capture devices available")
            return
        }

        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        let sortedFormats = formats.map {
            (format: $0, dimensions: CMVideoFormatDescriptionGetDimensions($0.formatDescription))
        }
        .sorted { $0.dimensions.area < $1.dimensions.area }

        var selectedFormat = sortedFormats.first

        if let preferredFormat = videoOptions.preferredFormat,
           let foundFormat = sortedFormats.first(where: { $0.format == preferredFormat }) {
            selectedFormat = foundFormat
        } else {
            selectedFormat = sortedFormats.first(where: { $0.dimensions.area >= videoOptions.preferredDimensions.area })
        }

        guard let selectedFormat = selectedFormat, let fpsRange = selectedFormat.format.fpsRange() else {
            log.warning("Unable to resolve format")
            return
        }

        var selectedFps = videoOptions.preferredFps

        if !fpsRange.contains(selectedFps) {
            log.warning("requested fps: \(videoOptions.preferredFps) not available: \(fpsRange) and will be clamped")
            selectedFps = selectedFps.clamped(to: fpsRange)
        }

        if RPScreenRecorder.shared().isRecording {
            return
        }
        
        RPScreenRecorder.shared().startCapture { sampleBuffer, type, error in
            if type == .video {
                guard CMSampleBufferGetNumSamples(sampleBuffer) == 1,
                      CMSampleBufferIsValid(sampleBuffer),
                      CMSampleBufferDataIsReady(sampleBuffer) else {
                    return
                }

                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    return
                }

                let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let timeStampNs = Int64(CMTimeGetSeconds(timeStamp) * Double(NSEC_PER_SEC))
                
                let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
                let rtcFrame = RTCVideoFrame(
                    buffer: rtcBuffer,
                    rotation: ._0,
                    timeStampNs: timeStampNs
                )

                self.videoCaptureHandler?.capturer(self.videoCapturer, didCapture: rtcFrame)
                self.videoSource.adaptOutputFormat(
                    toWidth: selectedFormat.dimensions.width,
                    height: selectedFormat.dimensions.height,
                    fps: Int32(selectedFps)
                )
            }
        }
    }
    
    func stopCameraCapture() {
        (videoCapturer as? RTCCameraVideoCapturer)?.stopCapture()
    }

}
