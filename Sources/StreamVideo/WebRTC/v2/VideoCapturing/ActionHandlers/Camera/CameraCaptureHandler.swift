//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import CoreMedia
import Foundation
import StreamWebRTC

final class CameraCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    private struct Configuration: Equatable, Sendable {
        /// The camera position to use for capturing (e.g., front or back camera).
        var position: AVCaptureDevice.Position
        /// The dimensions (width and height) for the captured video.
        var dimensions: CGSize
        /// The frame rate for video capturing in frames per second (fps).
        var frameRate: Int
    }

    @Injected(\.captureDeviceProvider) private var captureDeviceProvider
    @Injected(\.permissions) private var permissions

    private var activeConfiguration: Configuration?

    // MARK: - StreamVideoCapturerActionHandler

    /// Handles camera capture actions.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(position, dimensions, frameRate, videoSource, videoCapturer, videoCapturerDelegate, _):
            guard let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer else {
                return
            }
            try await execute(
                configuration: .init(
                    position: position,
                    dimensions: dimensions,
                    frameRate: frameRate
                ),
                videoSource: videoSource,
                videoCapturer: cameraCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )

        case let .setCameraPosition(position, videoSource, videoCapturer, videoCapturerDelegate):
            guard
                let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer,
                let activeConfiguration
            else {
                return
            }
            try await execute(
                configuration: .init(
                    position: position,
                    dimensions: activeConfiguration.dimensions,
                    frameRate: activeConfiguration.frameRate
                ),
                videoSource: videoSource,
                videoCapturer: cameraCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )

        case let .updateCaptureQuality(dimensions, device, videoSource, videoCapturer, videoCapturerDelegate):
            guard
                let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer,
                let activeConfiguration
            else {
                return
            }
            try await updateCaptureQuality(
                configuration: .init(
                    position: activeConfiguration.position,
                    dimensions: dimensions,
                    frameRate: activeConfiguration.frameRate
                ),
                captureDevice: device,
                videoSource: videoSource,
                videoCapturer: cameraCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )

        case let .stopCapture(videoCapturer):
            activeConfiguration = nil
            guard
                let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer
            else {
                return
            }
            await executeStop(cameraVideoCapturer)
        default:
            break
        }
    }

    // MARK: - Private

    private func execute(
        configuration: Configuration,
        videoSource: RTCVideoSource,
        videoCapturer: RTCCameraVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate
    ) async throws {
        guard configuration != activeConfiguration else {
            log.debug(
                "\(type(of: self)) performed no action as configuration wasn't changed.",
                subsystems: .videoCapturer
            )
            return
        }

        let hasPermission = try await permissions.requestCameraPermission()

        guard hasPermission else {
            throw ClientError("Camera access permission request failed.")
        }

        guard
            let captureDevice = captureDeviceProvider.device(for: configuration.position)
        else {
            throw ClientError("\(type(of: self)) was unable to perform action because no capture device was found.")
        }

        guard let outputFormat = captureDevice.outputFormat(
            preferredDimensions: .init(configuration.dimensions),
            preferredFrameRate: configuration.frameRate,
            preferredMediaSubType: videoCapturer.preferredOutputPixelFormat()
        ) else {
            throw ClientError(
                "\(type(of: self)) was unable to perform action because no output format found for dimensions:\(configuration.dimensions) frameRate:\(configuration.frameRate)."
            )
        }

        adaptOutputFormatIfRequired(
            outputFormat,
            on: videoSource,
            configuration: configuration
        )

        // If the capturer is already active, since iOS 18, we need to explicitly
        // stop the current capturing session before we start one with the new
        // configuration.
        if activeConfiguration != nil {
            await videoCapturer.stopCapture()
        }

        try await startCapture(
            on: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            with: captureDevice,
            format: outputFormat,
            configuration: configuration
        )

        activeConfiguration = configuration

        log.debug(
            "\(type(of: self)) started capturing with configuration position:\(configuration.position) dimensions:\(configuration.dimensions) frameRate:\(configuration.frameRate).",
            subsystems: .videoCapturer
        )
    }

    private func adaptOutputFormatIfRequired(
        _ outputFormat: AVCaptureDevice.Format,
        on videoSource: RTCVideoSource,
        configuration: Configuration
    ) {
        let outputFormatDimensions = outputFormat.dimensions

        guard
            outputFormatDimensions.area != CMVideoDimensions(configuration.dimensions).area
        else {
            log.debug(
                "\(type(of: self)) videoSource adaptation isn't required for dimensions:\(CGSize(outputFormatDimensions)) frameRate:\(configuration.frameRate).",
                subsystems: .videoCapturer
            )
            return
        }

        videoSource.adaptOutputFormat(
            toWidth: outputFormatDimensions.width,
            height: outputFormatDimensions.height,
            fps: Int32(configuration.frameRate.clamped(to: outputFormat.frameRateRange))
        )

        log.debug(
            "\(type(of: self)) videoSource adaptation executed for dimensions:\(CGSize(outputFormatDimensions)) frameRate:\(configuration.frameRate).",
            subsystems: .videoCapturer
        )
    }

    private func startCapture(
        on videoCapturer: RTCCameraVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate,
        with device: CaptureDeviceProtocol,
        format: AVCaptureDevice.Format,
        configuration: Configuration
    ) async throws {
        try await videoCapturer.startCapture(
            with: device,
            format: format,
            fps: configuration.frameRate.clamped(to: format.frameRateRange)
        )

        if let videoCapturerDelegate = videoCapturerDelegate as? StreamVideoCaptureHandler {
            videoCapturerDelegate.currentCameraPosition = device.position
        }
    }

    private func updateCaptureQuality(
        configuration: Configuration,
        captureDevice: AVCaptureDevice,
        videoSource: RTCVideoSource,
        videoCapturer: RTCCameraVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate
    ) async throws {
        guard configuration != activeConfiguration else {
            log.debug(
                "\(type(of: self)) performed no action as configuration wasn't changed.",
                subsystems: .videoCapturer
            )
            return
        }

        guard let outputFormat = captureDevice.outputFormat(
            preferredDimensions: .init(configuration.dimensions),
            preferredFrameRate: configuration.frameRate,
            preferredMediaSubType: videoCapturer.preferredOutputPixelFormat()
        ) else {
            throw ClientError(
                "\(type(of: self)) was unable to perform action because no output format found for dimensions:\(configuration.dimensions) frameRate:\(configuration.frameRate)."
            )
        }

        adaptOutputFormatIfRequired(
            outputFormat,
            on: videoSource,
            configuration: configuration
        )

        try await startCapture(
            on: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            with: captureDevice,
            format: outputFormat,
            configuration: configuration
        )

        activeConfiguration = configuration

        log.debug(
            "\(type(of: self)) updated capturing with configuration position:\(configuration.position) dimensions:\(configuration.dimensions) frameRate:\(configuration.frameRate).",
            subsystems: .videoCapturer
        )
    }

    private func executeStop(_ videoCapturer: RTCCameraVideoCapturer) async {
        await withCheckedContinuation { continuation in
            videoCapturer.stopCapture {
                continuation.resume()
            }
        }
        log.debug("\(type(of: self)) stopped capturing.", subsystems: .videoCapturer)
    }
}
