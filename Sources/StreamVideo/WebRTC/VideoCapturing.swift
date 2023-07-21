//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

protocol VideoCapturing {
    func startCapture(device: AVCaptureDevice?) async throws
    func stopCapture() async throws
}

extension VideoCapturing {
    func outputFormat(
        for device: AVCaptureDevice,
        videoOptions: VideoOptions
    ) -> (format: AVCaptureDevice.Format?, dimensions: CMVideoDimensions?, fps: Int) {
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
            return (format: nil, dimensions: nil, fps: 0)
        }

        var selectedFps = videoOptions.preferredFps

        if !fpsRange.contains(selectedFps) {
            log.warning("requested fps: \(videoOptions.preferredFps) not available: \(fpsRange) and will be clamped")
            selectedFps = selectedFps.clamped(to: fpsRange)
        }
        
        return (format: selectedFormat.format, dimensions: selectedFormat.dimensions, fps: selectedFps)
    }
}

protocol CameraVideoCapturing: VideoCapturing {    
    func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) async throws
    func setVideoFilter(_ videoFilter: VideoFilter?)
    func capturingDevice(for cameraPosition: AVCaptureDevice.Position) -> AVCaptureDevice?
}
