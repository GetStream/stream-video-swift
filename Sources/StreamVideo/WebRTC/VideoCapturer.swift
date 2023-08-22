//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

class VideoCapturer: CameraVideoCapturing {
    
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
        let handler = StreamVideoCaptureHandler(source: videoSource, filters: videoFilters)
        videoCaptureHandler = handler
        videoCapturer = RTCCameraVideoCapturer(delegate: handler)
        #endif
    }
    
    func capturingDevice(for cameraPosition: AVCaptureDevice.Position) -> AVCaptureDevice? {
        VideoCapturingUtils.capturingDevice(for: cameraPosition)
    }
    
    func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) async throws {
        guard let device = VideoCapturingUtils.capturingDevice(for: cameraPosition) else {
            throw ClientError.Unexpected()
        }
        try await startCapture(device: device)
    }
    
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        videoCaptureHandler?.selectedFilter = videoFilter
    }
    
    func startCapture(device: AVCaptureDevice?) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard let videoCapturer = videoCapturer as? RTCCameraVideoCapturer, let device else {
                continuation.resume(throwing: ClientError.Unexpected())
                return
            }
            let outputFormat = VideoCapturingUtils.outputFormat(
                for: device,
                preferredFormat: videoOptions.preferredFormat,
                preferredDimensions: videoOptions.preferredDimensions,
                preferredFps: videoOptions.preferredFps
            )
            guard let selectedFormat = outputFormat.format, let dimensions = outputFormat.dimensions else {
                continuation.resume(throwing: ClientError.Unexpected())
                return
            }
            
            if dimensions.area != videoOptions.preferredDimensions.area {
                log.debug("Adapting video source output format")
                videoSource.adaptOutputFormat(
                    toWidth: dimensions.width,
                    height: dimensions.height,
                    fps: Int32(outputFormat.fps)
                )
            }
            
            videoCapturer.startCapture(
                with: device,
                format: selectedFormat,
                fps: outputFormat.fps
            ) { [weak self] error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    self?.videoCaptureHandler?.currentCameraPosition = device.position
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func stopCapture() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if let capturer = videoCapturer as? RTCCameraVideoCapturer {
                capturer.stopCapture {
                    continuation.resume(returning: ())
                }
            } else {
                continuation.resume(returning: ())
            }
        }
    }
}

extension CMVideoDimensions {
    
    public static var full = CMVideoDimensions(width: 1280, height: 720)
    public static var half = CMVideoDimensions(width: 640, height: 480)
    public static var quarter = CMVideoDimensions(width: 480, height: 360)
    
    var area: Int32 {
        width * height
    }
}

extension AVCaptureDevice.Format {

    // computes a ClosedRange of supported FPSs for this format
    func fpsRange() -> ClosedRange<Int> {
        videoSupportedFrameRateRanges
            .map { $0.toRange() }
            .reduce(into: 0...0) { result, current in
            result = merge(range: result, with: current)
        }
    }
}

extension AVFrameRateRange {

    // convert to a ClosedRange
    func toRange() -> ClosedRange<Int> {
        Int(minFrameRate)...Int(maxFrameRate)
    }
}

internal func merge<T>(
    range range1: ClosedRange<T>,
    with range2: ClosedRange<T>
) -> ClosedRange<T> where T: Comparable {
    min(range1.lowerBound, range2.lowerBound)...max(range1.upperBound, range2.upperBound)
}

extension Comparable {

    // clamp a value within the range
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
