//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// A protocol that defines the properties and methods for a capture device.
protocol CaptureDeviceProtocol: Sendable {
    /// The physical position of the capture device (e.g., front or back).
    var position: AVCaptureDevice.Position { get }

    /// Returns a suitable output format based on the desired video settings.
    ///
    /// This method searches the available formats on the capture device to find
    /// one that matches the given dimensions, frame rate, and media subtype.
    ///
    /// - Parameters:
    ///   - preferredDimensions: Desired width and height of the video.
    ///   - preferredFrameRate: Desired number of frames per second.
    ///   - preferredMediaSubType: Desired pixel format or encoding (e.g., '420v').
    /// - Returns: A format that best matches the criteria, or `nil` if none found.
    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int,
        preferredMediaSubType: FourCharCode
    ) -> AVCaptureDevice.Format?
}

/// Extend `AVCaptureDevice` to conform to `CaptureDeviceProtocol`.
extension AVCaptureDevice: CaptureDeviceProtocol {}
