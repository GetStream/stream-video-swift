//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

class VideoCapturer: CameraVideoCapturing {
    
    private var videoCapturer: RTCVideoCapturer
    private var videoOptions: VideoOptions
    private let videoSource: RTCVideoSource
    private var videoCaptureHandler: StreamVideoCaptureHandler?

    private var simulatorStreamFile: URL? = InjectedValues[\.simulatorStreamFile]

    init(
        videoSource: RTCVideoSource,
        videoOptions: VideoOptions,
        videoFilters: [VideoFilter]
    ) {
        self.videoOptions = videoOptions
        self.videoSource = videoSource
        #if targetEnvironment(simulator)
        if let url = simulatorStreamFile {
            let handler = StreamVideoCaptureHandler(source: videoSource, filters: videoFilters)
            videoCaptureHandler = handler
            videoCapturer = SimulatorScreenCapturer(delegate: handler, videoURL: url)
        } else {
            videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        }
        #else
        let handler = StreamVideoCaptureHandler(source: videoSource, filters: videoFilters)
        videoCaptureHandler = handler
        videoCapturer = RTCCameraVideoCapturer(delegate: handler)
        checkForBackgroundCameraAccess()
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
        try await withCheckedThrowingContinuation { continuation in
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
        try await withCheckedThrowingContinuation { continuation in
            if let capturer = videoCapturer as? RTCCameraVideoCapturer {
                capturer.stopCapture {
                    continuation.resume(returning: ())
                }
            } else {
                continuation.resume(returning: ())
            }
        }
    }

    /// Initiates a focus and exposure operation at the specified point on the camera's view.
    ///
    /// This method attempts to focus the camera and set the exposure at a specific point by interacting
    /// with the device's capture session.
    /// It requires the `videoCapturer` property to be cast to `RTCCameraVideoCapturer`, and for
    /// a valid `AVCaptureDeviceInput` to be accessible.
    /// If these conditions are not met, it throws a `ClientError.Unexpected` error.
    ///
    /// - Parameter point: A `CGPoint` representing the location within the view where the camera
    /// should adjust focus and exposure.
    /// - Throws: A `ClientError.Unexpected` error if the necessary video capture components are
    /// not available or properly configured.
    ///
    /// - Note: Ensure that the `point` is normalized to the camera's coordinate space, ranging
    /// from (0,0) at the top-left to (1,1) at the bottom-right.
    func focus(at point: CGPoint) throws {
        guard
            let captureSession = (videoCapturer as? RTCCameraVideoCapturer)?.captureSession,
            let device = captureSession.inputs.first as? AVCaptureDeviceInput
        else {
            throw ClientError.Unexpected()
        }

        do {
            try device.device.lockForConfiguration()

            if device.device.isFocusPointOfInterestSupported {
                log.debug("Will focus at point: \(point)")
                device.device.focusPointOfInterest = point

                if device.device.isFocusModeSupported(.autoFocus) {
                    device.device.focusMode = .autoFocus
                } else {
                    log.warning("There are no supported focusMode.")
                }

                log.debug("Will set exposure at point: \(point)")
                if device.device.isExposurePointOfInterestSupported {
                    device.device.exposurePointOfInterest = point

                    if device.device.isExposureModeSupported(.autoExpose) {
                        device.device.exposureMode = .autoExpose
                    } else {
                        log.warning("There are no supported exposureMode.")
                    }
                }
            }

            device.device.unlockForConfiguration()
        } catch {
            log.error(error)
        }
    }

    // MARK: - private
    
    private func checkForBackgroundCameraAccess() {
        if #available(iOS 16, *) {
            guard let captureSession = (videoCapturer as? RTCCameraVideoCapturer)?.captureSession else {
                return
            }
            // Configure the capture session.
            captureSession.beginConfiguration()

            if captureSession.isMultitaskingCameraAccessSupported {
                // Enable use of the camera in multitasking modes.
                captureSession.isMultitaskingCameraAccessEnabled = true
            }
            captureSession.commitConfiguration()
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
