//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

enum VideoCapturingUtils {
    static func codecs(
        preferredFormat: AVCaptureDevice.Format?,
        preferredDimensions: CMVideoDimensions,
        preferredFps: Int,
        preferredBitrate: Int
    ) throws -> [VideoCodec] {
        guard let device = VideoCapturingUtils.capturingDevice(for: .front) else {
            throw ClientError.Unexpected()
        }
        let outputFormat = VideoCapturingUtils.outputFormat(
            for: device,
            preferredFormat: preferredFormat,
            preferredDimensions: preferredDimensions,
            preferredFps: preferredFps
        )
        guard let targetResolution = outputFormat.dimensions else { throw ClientError.Unexpected() }
        return makeCodecs(
            with: targetResolution,
            preferredBitrate: preferredBitrate
        )
    }
    
    static func makeCodecs(
        with targetResolution: CMVideoDimensions,
        preferredBitrate: Int
    ) -> [VideoCodec] {
        var codecs = [VideoCodec]()
        var scaleDownFactor: Int32 = 1
        let qualities = ["f", "h", "q"]
        for quality in qualities {
            let width = targetResolution.width / scaleDownFactor
            let height = targetResolution.height / scaleDownFactor
            let bitrate = preferredBitrate / Int(scaleDownFactor)
            let dimensions = CMVideoDimensions(width: width, height: height)
            let codec = VideoCodec(
                dimensions: dimensions,
                quality: quality,
                maxBitrate: bitrate
            )
            codecs.append(codec)
            scaleDownFactor *= 2
        }
        return codecs.reversed()
    }
    
    static func outputFormat(
        for device: AVCaptureDevice,
        preferredFormat: AVCaptureDevice.Format?,
        preferredDimensions: CMVideoDimensions,
        preferredFps: Int
    ) -> (format: AVCaptureDevice.Format?, dimensions: CMVideoDimensions?, fps: Int) {
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        let sortedFormats = formats.map {
            let dimensions = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
            let diff = abs(dimensions.area - preferredDimensions.area)
            return (format: $0, dimensions: dimensions, diff: diff)
        }
        .sorted { $0.dimensions.area < $1.dimensions.area }

        var selectedFormat = sortedFormats.first

        if let preferredFormat = preferredFormat,
           let foundFormat = sortedFormats.first(where: { $0.format == preferredFormat }) {
            selectedFormat = foundFormat
        } else {
            selectedFormat = sortedFormats.first(where: { $0.dimensions.area >= preferredDimensions.area
                    && $0.format.fpsRange().contains(preferredFps)
            })
            
            if selectedFormat == nil {
                selectedFormat = sortedFormats.first(where: { $0.dimensions.area >= preferredDimensions.area })
            }

            // In case we cannot find a matching format based on the preferredDimensions
            // we will choose the closest one.
            if selectedFormat == nil {
                selectedFormat = sortedFormats.min(by: { $0.diff < $1.diff })
            }
        }

        guard let selectedFormat = selectedFormat else {
            log
                .warning(
                    "Unable to resolve format with preferredDimensions:\(preferredDimensions.width)x\(preferredDimensions.height) preferredFormat:\(String(describing: preferredFormat)) preferredFPS:\(preferredFps)"
                )
            return (format: nil, dimensions: nil, fps: 0)
        }
        log
            .debug(
                "SelectedFormat dimensions:\(selectedFormat.dimensions.width)x\(selectedFormat.dimensions.height) format:\(selectedFormat.format) diff:\(selectedFormat.diff)"
            )

        var selectedFps = preferredFps
        let fpsRange = selectedFormat.format.fpsRange()

        if !fpsRange.contains(selectedFps) {
            log.warning("requested fps: \(preferredFps) not available: \(fpsRange) and will be clamped")
            selectedFps = selectedFps.clamped(to: fpsRange)
        }
        
        return (format: selectedFormat.format, dimensions: selectedFormat.dimensions, fps: selectedFps)
    }
    
    static func capturingDevice(for cameraPosition: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = RTCCameraVideoCapturer.captureDevices()
        
        guard let device = devices.first(where: { $0.position == cameraPosition }) ?? devices.first else {
            log.warning("No camera video capture devices available")
            return nil
        }
        
        return device
    }
}
