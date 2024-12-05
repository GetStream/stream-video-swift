//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

class VideoCapturer: CameraVideoCapturing {
    
    private var videoCapturer: RTCVideoCapturer?
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
        videoCapturer = RTCCameraVideoCapturer(delegate: handler, captureSession: AVCaptureSession())
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
            guard let videoCapturer = videoCapturer as? RTCCameraVideoCapturer else {
                continuation.resume()
                return
            }

            guard let device else {
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
        } as Void
    }
    
    func stopCapture() async throws {
        try await withCheckedThrowingContinuation { continuation in
            if let capturer = videoCapturer as? RTCCameraVideoCapturer {
                capturer.stopCapture {
                    continuation.resume(returning: ())
                }
            } else if let capturer = videoCapturer as? SimulatorScreenCapturer {
                capturer.stopCapturing()
                continuation.resume(returning: ())
            } else {
                continuation.resume(returning: ())
            }
        }
    }

    func updateCaptureQuality(
        _ layers: [VideoLayer],
        on device: AVCaptureDevice?
    ) async throws {
        guard
            let videoCapturer = videoCapturer as? RTCCameraVideoCapturer,
            let device
        else {
            return
        }

        let preferredDimensions: CMVideoDimensions = {
            if layers.first(where: { $0.quality == VideoLayer.full.quality }) != nil {
                return .full
            } else if layers.first(where: { $0.quality == VideoLayer.half.quality }) != nil {
                return .half
            } else {
                return .quarter
            }
        }()
        let outputFormat = VideoCapturingUtils.outputFormat(
            for: device,
            preferredFormat: videoOptions.preferredFormat,
            preferredDimensions: preferredDimensions,
            preferredFps: videoOptions.preferredFps
        )
        guard
            let selectedFormat = outputFormat.format,
            let dimensions = outputFormat.dimensions
        else {
            return
        }

        if dimensions.area != videoOptions.preferredDimensions.area {
            log.debug(
                "Adapting video source output format (\(dimensions.width)x\(dimensions.height))",
                subsystems: .webRTC
            )
            videoSource.adaptOutputFormat(
                toWidth: dimensions.width,
                height: dimensions.height,
                fps: Int32(outputFormat.fps)
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            videoCapturer.startCapture(
                with: device,
                format: selectedFormat,
                fps: outputFormat.fps
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
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
            let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer,
            let activeCaptureDevice = cameraVideoCapturer.captureSession.activeVideoCaptureDevice
        else {
            throw ClientError.Unexpected()
        }
        
        try activeCaptureDevice.lockForConfiguration()
        
        if activeCaptureDevice.isFocusPointOfInterestSupported {
            log.debug("Will focus at point: \(point)")
            activeCaptureDevice.focusPointOfInterest = point
            
            if activeCaptureDevice.isFocusModeSupported(.autoFocus) {
                activeCaptureDevice.focusMode = .autoFocus
            } else {
                log.warning("There are no supported focusMode.")
            }
            
            log.debug("Will set exposure at point: \(point)")
            if activeCaptureDevice.isExposurePointOfInterestSupported {
                activeCaptureDevice.exposurePointOfInterest = point
                
                if activeCaptureDevice.isExposureModeSupported(.autoExpose) {
                    activeCaptureDevice.exposureMode = .autoExpose
                } else {
                    log.warning("There are no supported exposureMode.")
                }
            }
        }
        
        activeCaptureDevice.unlockForConfiguration()
    }
    
    /// Adds the `AVCapturePhotoOutput` on the `CameraVideoCapturer` to enable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCapturePhotoOutput` for capturing photos. This enhancement allows applications to capture
    /// still images while video capturing is ongoing.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be added
    /// to the `CameraVideoCapturer`. This output enables the capture of photos alongside video
    /// capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support photo output functionality, an appropriate error
    /// will be thrown to indicate that the operation is not supported.
    ///
    /// - Warning: A maximum of one output of each type may be added.
    func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        guard
            let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer,
            cameraVideoCapturer.captureSession.canAddOutput(capturePhotoOutput)
        else {
            throw ClientError.Unexpected("Cannot set capturePhotoOutput for videoCapturer of type:\(type(of: videoCapturer)).")
        }
        
        cameraVideoCapturer.captureSession.beginConfiguration()
        cameraVideoCapturer.captureSession.addOutput(capturePhotoOutput)
        cameraVideoCapturer.captureSession.commitConfiguration()
    }

    /// Removes the `AVCapturePhotoOutput` from the `CameraVideoCapturer` to disable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` by removing an
    /// `AVCapturePhotoOutput` previously added for capturing photos. This action is necessary when
    /// the application needs to stop capturing still images or when adjusting the capturing setup. It ensures
    /// that the video capturing process can continue without the overhead or interference of photo
    /// capturing capabilities.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output disables the capture of photos alongside
    /// video capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support the removal of photo output functionality, an
    /// appropriate error will be thrown to indicate that the operation is not supported.
    ///
    /// - Note: Ensure that the `AVCapturePhotoOutput` being removed was previously added to the
    /// `CameraVideoCapturer`. Attempting to remove an output that is not currently added will not
    /// affect the capture session but may result in unnecessary processing.
    func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        guard
            let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer
        else {
            throw ClientError.Unexpected("Cannot remove capturePhotoOutput for videoCapturer of type:\(type(of: videoCapturer)).")
        }

        cameraVideoCapturer.captureSession.beginConfiguration()
        cameraVideoCapturer.captureSession.removeOutput(capturePhotoOutput)
        cameraVideoCapturer.captureSession.commitConfiguration()
    }

    /// Adds an `AVCaptureVideoDataOutput` to the `CameraVideoCapturer` for video frame
    /// processing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCaptureVideoDataOutput`, enabling the processing of video frames. This is particularly
    /// useful for applications that require access to raw video data for analysis, filtering, or other processing
    /// tasks while video capturing is in progress.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be added to
    /// the `CameraVideoCapturer`. This output facilitates the capture and processing of live video
    /// frames.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an
    /// `AVCaptureVideoDataOutput`. This functionality is specific to `RTCCameraVideoCapturer`
    /// instances. If the current `CameraVideoCapturer` does not accommodate video output, an error
    /// will be thrown to signify the unsupported operation.
    ///
    /// - Warning: A maximum of one output of each type may be added. For applications linked on or
    /// after iOS 16.0, this restriction no longer applies to AVCaptureVideoDataOutputs. When adding more
    /// than one AVCaptureVideoDataOutput, AVCaptureSession.hardwareCost must be taken into account.
    func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        guard
            let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer,
            cameraVideoCapturer.captureSession.canAddOutput(videoOutput)
        else {
            throw ClientError.Unexpected("Cannot set videoOutput for videoCapturer of type:\(type(of: videoCapturer)).")
        }
        cameraVideoCapturer.captureSession.beginConfiguration()
        cameraVideoCapturer.captureSession.addOutput(videoOutput)
        cameraVideoCapturer.captureSession.commitConfiguration()
    }

    /// Removes an `AVCaptureVideoDataOutput` from the `CameraVideoCapturer` to disable
    /// video frame processing capabilities.
    ///
    /// This method reconfigures the local user's `CameraVideoCapturer` by removing an
    /// `AVCaptureVideoDataOutput` that was previously added. This change is essential when the
    /// application no longer requires access to raw video data for analysis, filtering, or other processing
    /// tasks, or when adjusting the video capturing setup for different operational requirements. It ensures t
    /// hat video capturing can proceed without the additional processing overhead associated with
    /// handling video frame outputs.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output stops the capture and processing of live video
    /// frames through the specified output, simplifying the capture session.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCaptureVideoDataOutput`. This functionality is tailored for `RTCCameraVideoCapturer`
    /// instances. If the `CameraVideoCapturer` being used does not permit the removal of video outputs,
    /// an error will be thrown to indicate the unsupported operation.
    ///
    /// - Note: It is crucial to ensure that the `AVCaptureVideoDataOutput` intended for removal
    /// has been previously added to the `CameraVideoCapturer`. Trying to remove an output that is
    /// not part of the capture session will have no negative impact but could lead to unnecessary processing
    /// and confusion.
    func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        guard
            let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer
        else {
            throw ClientError.Unexpected("Cannot remove videoOutput for videoCapturer of type:\(type(of: videoCapturer)).")
        }
        cameraVideoCapturer.captureSession.beginConfiguration()
        cameraVideoCapturer.captureSession.removeOutput(videoOutput)
        cameraVideoCapturer.captureSession.commitConfiguration()
    }

    /// Zooms the camera video by the specified factor.
    ///
    /// This method attempts to zoom the camera's video feed by adjusting the `videoZoomFactor` of
    /// the camera's active device. It first checks if the video capturer is of type `RTCCameraVideoCapturer`
    /// and if the current camera device supports zoom by verifying that the `videoMaxZoomFactor` of
    /// the active format is greater than 1.0. If these conditions are met, it proceeds to apply the requested
    /// zoom factor, clamping it within the supported range to avoid exceeding the device's capabilities.
    ///
    /// - Parameter factor: The desired zoom factor. A value of 1.0 represents no zoom, while values
    /// greater than 1.0 increase the zoom level. The factor is clamped to the maximum zoom factor supported
    /// by the device to ensure it remains within valid bounds.
    ///
    /// - Throws: `ClientError.Unexpected` if the video capturer is not of type
    /// `RTCCameraVideoCapturer`, or if the device does not support zoom. Also, throws an error if
    /// locking the device for configuration fails.
    ///
    /// - Note: This method should be used cautiously, as setting a zoom factor significantly beyond the
    /// optimal range can degrade video quality.
    func zoom(by factor: CGFloat) throws {
        guard
            let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer,
            let activeCaptureDevice = cameraVideoCapturer.captureSession.activeVideoCaptureDevice,
            activeCaptureDevice.activeFormat.videoMaxZoomFactor > 1.0 // That ensures that the devices supports zoom.
        else {
            throw ClientError.Unexpected("Cannot zoom captureDevice for videoCapturer of type:\(type(of: videoCapturer)).")
        }
        
        try activeCaptureDevice.lockForConfiguration()
        let zoomFactor = max(1.0, min(factor, activeCaptureDevice.activeFormat.videoMaxZoomFactor))
        activeCaptureDevice.videoZoomFactor = zoomFactor
        activeCaptureDevice.unlockForConfiguration()
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
