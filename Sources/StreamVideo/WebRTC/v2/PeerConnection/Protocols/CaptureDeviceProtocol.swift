//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// A protocol that defines the properties and methods for a capture device.
public protocol CaptureDeviceProtocol: Sendable {
    /// The position of the capture device.
    var position: AVCaptureDevice.Position { get }

    /// Returns the output format for the capture device based on the preferred
    /// dimensions and frame rate.
    ///
    /// - Parameters:
    ///   - preferredDimensions: The preferred dimensions for the video output.
    ///   - preferredFrameRate: The preferred frame rate for the video output.
    /// - Returns: An optional `AVCaptureDevice.Format` that matches the
    ///   preferred dimensions and frame rate.
    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int
    ) -> AVCaptureDevice.Format?
}

/// Extend `AVCaptureDevice` to conform to `CaptureDeviceProtocol`.
extension AVCaptureDevice: CaptureDeviceProtocol {}
