//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import ReplayKit

class ScreenshareCapturer: VideoCapturing {
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
    
    func startCapture(device: AVCaptureDevice?) async throws {
        let devices = RTCCameraVideoCapturer.captureDevices()
        
        guard let device = devices.first else {
            throw ClientError.Unexpected()
        }
        
        if RPScreenRecorder.shared().isRecording {
            return
        }
        
        RPScreenRecorder.shared().isMicrophoneEnabled = false
        
        return try await withCheckedThrowingContinuation { continuation in
            RPScreenRecorder.shared().startCapture(handler: { [weak self] sampleBuffer, type, error in
                guard let self else { return }
                self.handle(sampleBuffer: sampleBuffer, type: type, for: device)
            }) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func stopCapture() async throws {
        try await stopScreensharing()
        await (videoCapturer as? RTCCameraVideoCapturer)?.stopCapture()
    }
    
    func handle(sampleBuffer: CMSampleBuffer, type: RPSampleBufferType, for device: AVCaptureDevice) {
        let outputFormat = VideoCapturingUtils.outputFormat(
            for: device,
            preferredFormat: videoOptions.preferredFormat,
            preferredDimensions: videoOptions.preferredDimensions,
            preferredFps: videoOptions.preferredFps
        )

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
            if let dimensions = outputFormat.dimensions {
                self.videoSource.adaptOutputFormat(
                    toWidth: dimensions.width,
                    height: dimensions.height,
                    fps: Int32(outputFormat.fps)
                )
            }
        }
    }
    
    private func stopScreensharing() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard RPScreenRecorder.shared().isRecording else {
                continuation.resume(returning: ())
                return
            }
            RPScreenRecorder.shared().stopCapture { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

}
