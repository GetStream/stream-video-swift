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
    
    func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position, completion: @escaping () -> ()) {
        guard let device = capturingDevice(for: cameraPosition) else { return }
        startCapture(device: device, completion: completion)
    }
    
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        videoCaptureHandler?.selectedFilter = videoFilter
    }
    
    func capturingDevice(for cameraPosition: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = RTCCameraVideoCapturer.captureDevices()
        
        guard let device = devices.first(where: { $0.position == cameraPosition }) ?? devices.first else {
            log.warning("No camera video capture devices available")
            return nil
        }
        
        return device
    }
    
    func startCapture(device: AVCaptureDevice?, completion: @escaping () -> ()) {
        guard let videoCapturer = videoCapturer as? RTCCameraVideoCapturer, let device else { return }
        let outputFormat = self.outputFormat(for: device, videoOptions: videoOptions)
        guard let selectedFormat = outputFormat.format, let dimensions = outputFormat.dimensions else { return }
        
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
        ) { [weak self] _ in
            self?.videoCaptureHandler?.currentCameraPosition = device.position
            completion()
        }
    }
    
    func stopCapture() {
        (videoCapturer as? RTCCameraVideoCapturer)?.stopCapture()
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
    func fpsRange() -> ClosedRange<Int>? {
        videoSupportedFrameRateRanges
            .map { $0.toRange() }
            .reduce(into: nil as ClosedRange<Int>?) { result, current in
                guard let previous = result else {
                    result = current
                    return
                }

                // merge previous element
                result = merge(range: previous, with: current)
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
