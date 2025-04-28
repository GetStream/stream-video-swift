//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation
import StreamCore

/// A class that defines video capture policies used by the `LocalVideoAdapter`
/// to adjust video capture quality based on instructions from the SFU
/// (Selective Forwarding Unit).
///
/// ## Overview
/// On devices with limited processing power, video capture often starts at
/// full quality, even if the SFU requests lower quality streams (e.g., half
/// or quarter resolution). This mismatch can result in unnecessary processing
/// overhead as the device continues to capture at a higher quality than needed.
///
/// By aligning the capture quality with the SFU's requests, `VideoCapturePolicy`
/// helps reduce processing costs and improves performance, particularly on
/// older or less powerful devices.
public class VideoCapturePolicy: @unchecked Sendable {

    /// Updates the video capture quality based on active encodings and the current session.
    ///
    /// - Parameters:
    ///   - activeEncodings: A set of strings representing the active encoding qualities.
    ///   - activeSession: The current video capture session, if any.
    ///
    /// Override this method in subclasses to implement specific policies for
    /// adjusting capture quality. By default, this method performs no action.
    func updateCaptureQuality(
        with preferredDimensions: CGSize,
        for activeSession: VideoCaptureSession?
    ) async throws { /* No operation by default */ }
}

/// A concrete implementation of `VideoCapturePolicy` that dynamically adapts
/// video capture quality based on system conditions and SFU requests.
///
/// ## Features
/// - Adjusts video capture quality when the device's thermal state is `.serious`
///   or higher, or when the device lacks a neural engine.
/// - Only updates capture quality if the requested encodings differ from the
///   currently active encodings.
/// - Requires an active video capture session to make adjustments.
final class AdaptiveVideoCapturePolicy: VideoCapturePolicy, @unchecked Sendable {

    @Injected(\.thermalStateObserver) private var thermalStateObserver

    /// Determines if the device has a neural engine, used for efficient resizing.
    private let neuralEngineExistsProvider: () -> Bool

    /// The most recently applied active encodings.
    private var lastPreferredDimensions: CGSize?

    /// Initializes the adaptive video capture policy.
    ///
    /// - Parameter neuralEngineExistsProvider: A closure to determine if the
    ///   device has a neural engine.
    init(_ neuralEngineExistsProvider: @escaping () -> Bool) {
        self.neuralEngineExistsProvider = neuralEngineExistsProvider
        super.init()
    }

    /// Updates the video capture quality based on active encodings and session details.
    ///
    /// - Parameters:
    ///   - activeEncodings: A set of strings representing the requested encoding qualities.
    ///   - activeSession: The current video capture session.
    ///
    /// This method dynamically adjusts the video capture quality by selecting
    /// the appropriate resolution (full, half, or quarter) based on the requested
    /// encodings. It only updates the quality if the thermal state or hardware
    /// conditions necessitate a change and if the requested encodings differ
    /// from the current settings.
    override func updateCaptureQuality(
        with preferredDimensions: CGSize,
        for activeSession: VideoCaptureSession?
    ) async throws {
        // Ensure there is a need to update capture quality and an active session exists.
        guard
            shouldUpdateCaptureQuality,
            lastPreferredDimensions != preferredDimensions,
            let activeSession
        else { return }

        // Apply the updated capture quality to the active session.
        try await activeSession
            .capturer
            .updateCaptureQuality(preferredDimensions)

        lastPreferredDimensions = preferredDimensions

        log.debug(
            "Video capture quality adapted to \(preferredDimensions).",
            subsystems: .webRTC
        )
    }

    // MARK: - Private Helpers

    /// Determines whether the capture quality should be updated.
    ///
    /// The capture quality is updated if the thermal state is `.serious` or
    /// higher, or if the device lacks a neural engine.
    private var shouldUpdateCaptureQuality: Bool {
        thermalStateObserver.state > .fair || !neuralEngineExistsProvider()
    }
}

extension VideoCapturePolicy {

    /// A video capture policy that does not adjust the capture quality.
    ///
    /// With the `none` policy, the device captures video at its initial
    /// quality settings, ignoring any requests from the SFU to adjust the
    /// quality. This may lead to unnecessary processing overhead, particularly
    /// on less powerful devices.
    static let none: VideoCapturePolicy = VideoCapturePolicy()

    /// A video capture policy that adapts the quality based on SFU instructions.
    ///
    /// The `adaptive` policy adjusts the video capture quality to match the
    /// quality requested by the SFU. By capturing video at the requested
    /// quality, this policy reduces processing overhead and improves
    /// performance, especially on older or less powerful devices.
    static let adaptive: VideoCapturePolicy = AdaptiveVideoCapturePolicy { neuralEngineExists }
}

extension VideoCapturePolicy: InjectionKey {

    /// The current video capture policy used for dependency injection.
    nonisolated(unsafe) public static var currentValue: VideoCapturePolicy = .adaptive
}

extension InjectedValues {

    /// Accessor for the `videoCapturePolicy` in the injected values.
    var videoCapturePolicy: VideoCapturePolicy {
        get { Self[VideoCapturePolicy.self] }
        set { Self[VideoCapturePolicy.self] = newValue }
    }
}
