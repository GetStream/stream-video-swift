//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension AVCaptureDevice {
    /// Selects an optimal output format for the capture device based on preferred dimensions, frame rate, and media subtype.
    ///
    /// - Parameters:
    ///   - preferredDimensions: The desired video dimensions (width and height in pixels).
    ///   - preferredFrameRate: The desired frame rate in frames per second.
    ///   - preferredMediaSubType: The desired pixel format or media encoding (e.g., '420v').
    /// - Returns: An `AVCaptureDevice.Format` instance that closely matches the preferred dimensions,
    ///   frame rate, and media subtype, or `nil` if no suitable format is found.
    ///
    /// This method evaluates the supported formats for the capture device, using the following criteria:
    /// 1. A format with the exact area, frame rate, and media subtype is prioritized.
    /// 2. A format with the exact area (dimensions) and frame rate.
    /// 3. If an exact match is unavailable, a format with a matching area (dimensions) is selected.
    /// 4. If no formats match the preferred area, the format with the smallest area difference is chosen.
    ///
    /// - Note: The formats are sorted by their area difference relative to the preferred dimensions
    ///   before applying the selection criteria.
    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int,
        preferredMediaSubType: FourCharCode
    ) -> AVCaptureDevice.Format? {
        // Fetch and sort the supported formats by area difference relative to preferred dimensions.
        let formats = RTCCameraVideoCapturer
            .supportedFormats(for: self)
            .sorted { $0.areaDiff(preferredDimensions) < $1.areaDiff(preferredDimensions) }

        // Try to find the best format based on the criteria, in descending priority order.
        if let result = formats.first(
            with: [
                .mediaSubType(preferredMediaSubType),
                .area(preferredDimensions: preferredDimensions),
                .frameRate(preferredFrameRate: preferredFrameRate)
            ]
        ) {
            return result
        } else if let result = formats.first(
            with: [
                .area(preferredDimensions: preferredDimensions),
                .frameRate(preferredFrameRate: preferredFrameRate)
            ]
        ) {
            return result
        } else if let result = formats.first(
            with: [.area(preferredDimensions: preferredDimensions)]
        ) {
            return result
        } else if let result = formats.first(
            with: [.minimumAreaDifference(preferredDimensions: preferredDimensions)]
        ) {
            return result
        } else {
            // Return nil if no suitable format is found.
            return nil
        }
    }
}

/// Extension adding utilities to filter and select `AVCaptureDevice.Format`
/// objects based on specific requirements.
extension Array where Element == AVCaptureDevice.Format {
    /// Requirements for filtering or selecting an `AVCaptureDevice.Format`.
    enum Requirement {
        /// Requires the format to have dimensions greater than or equal to
        /// the specified `preferredDimensions`.
        case area(preferredDimensions: CMVideoDimensions)

        /// Requires the format to support the specified frame rate.
        case frameRate(preferredFrameRate: Int)

        /// Requires the format to have the smallest area difference relative
        /// to the specified `preferredDimensions`.
        case minimumAreaDifference(preferredDimensions: CMVideoDimensions)

        /// Requires the format to have the specified media subtype.
        case mediaSubType(FourCharCode)
    }

    /// Selects the first format that meets the specified requirements.
    ///
    /// - Parameter requirements: An array of requirements that the format must
    ///   meet. Requirements are applied in the order they appear. This can
    ///   include resolution, frame rate, media subtype, or area difference.
    /// - Returns: The first `AVCaptureDevice.Format` that satisfies all the
    ///   provided requirements, or `nil` if none match.
    ///
    /// - Example:
    ///   ```swift
    ///   let formats = captureDevice.formats
    ///   let preferredDimensions = CMVideoDimensions(width: 1920, height: 1080)
    ///   let selectedFormat = formats.first(with: [
    ///       .area(preferredDimensions: preferredDimensions),
    ///       .frameRate(preferredFrameRate: 30)
    ///   ])
    ///   ```
    func first(with requirements: [Requirement]) -> AVCaptureDevice.Format? {
        var possibleResults = self

        for requirement in requirements {
            switch requirement {
            case let .area(preferredDimensions):
                // Filter formats with dimensions meeting or exceeding the preferred area.
                possibleResults = possibleResults.filter { $0.dimensions.area >= preferredDimensions.area }
            case let .frameRate(preferredFrameRate):
                // Filter formats that support the preferred frame rate.
                possibleResults = possibleResults.filter { $0.frameRateRange.contains(preferredFrameRate) }
            case let .minimumAreaDifference(preferredDimensions):
                // Find the format with the smallest area difference.
                let result = possibleResults
                    .min { $0.areaDiff(preferredDimensions) < $1.areaDiff(preferredDimensions) }
                if let result {
                    possibleResults = [result]
                } else {
                    possibleResults = []
                }

            case let .mediaSubType(value):
                possibleResults = possibleResults.filter { $0.mediaSubType == value }
            }
        }

        // Return the first format that meets all requirements.
        return possibleResults.first
    }
}
