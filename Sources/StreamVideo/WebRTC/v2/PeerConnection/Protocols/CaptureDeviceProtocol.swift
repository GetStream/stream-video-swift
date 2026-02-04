//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import CoreMedia

/// A protocol that defines the properties and methods for a capture device.
protocol CaptureDeviceProtocol: AnyObject, Sendable {
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
    ///   - preferredMediaSubType: Desired pixel format or encoding (e.g.,
    ///     '420v').
    /// - Returns: A format that best matches the criteria, or `nil` if none
    ///   found.
    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int,
        preferredMediaSubType: FourCharCode
    ) -> AVCaptureDevice.Format?
}

/// Extend `AVCaptureDevice` to conform to `CaptureDeviceProtocol`.
extension AVCaptureDevice: CaptureDeviceProtocol {}

/// A capture device that can report system pressure updates and accept
/// throttled frame rate changes.
protocol SystemPressureCaptureDevice: CaptureDeviceProtocol {
    /// Publisher emitting system pressure levels for this device.
    var systemPressureLevelPublisher: AnyPublisher<
        AVCaptureDevice.SystemPressureState.Level,
        Never
    > { get }

    /// Supported frame rate range for the active format.
    var activeFormatFrameRateRange: ClosedRange<Int> { get }

    /// Applies a fixed frame rate to the device.
    func applyFixedFrameRate(_ fps: Int) throws
}

extension AVCaptureDevice: SystemPressureCaptureDevice {
    var systemPressureLevelPublisher: AnyPublisher<
        AVCaptureDevice.SystemPressureState.Level,
        Never
    > {
        publisher(for: \.systemPressureState, options: [.initial, .new])
            .map(\.level)
            .eraseToAnyPublisher()
    }

    var activeFormatFrameRateRange: ClosedRange<Int> {
        activeFormat.frameRateRange
    }

    func applyFixedFrameRate(_ fps: Int) throws {
        try lockForConfiguration()
        let duration = CMTime(value: 1, timescale: CMTimeScale(fps))
        activeVideoMinFrameDuration = duration
        activeVideoMaxFrameDuration = duration
        unlockForConfiguration()
    }
}
