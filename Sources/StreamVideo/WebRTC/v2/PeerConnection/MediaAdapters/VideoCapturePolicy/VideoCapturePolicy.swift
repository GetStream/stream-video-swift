//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a video capture policy used by the `LocalVideoAdapter` to adjust video capture quality based on
/// instructions from the SFU (Selective Forwarding Unit).
///
/// On older devices, video capture often starts at full quality, but the SFU may request lower quality
/// streams (half or quarter resolution). Without adjusting the capture settings, the device continues to
/// capture at full quality even though it sends lower-quality streams, leading to unnecessary processing
/// overhead.
///
/// By adapting the capture quality to match the SFU's requests, this class helps reduce processing costs
/// and improve performance, especially on less powerful devices.
public class VideoCapturePolicy: @unchecked Sendable {
    /// Updates the capture quality based on active encodings and the active session.
    /// - Parameters:
    ///   - activeEncodings: A set of strings representing the active encoding qualities.
    ///   - activeSession: The current video capture session, if any.
    func updateCaptureQuality(
        with activeEncodings: Set<String>,
        for activeSession: VideoCaptureSession?
    ) async throws { /* No operation by default */ }
}

/// A final class that adapts the video capture quality dynamically. The policy requires the following criteria
/// in order to start adapting the capture quality:
/// - Either the thermal state is `.serious` or higher **or** the current device doesn't have a
/// neuralEngine (which is required for efficiently resizing frames).
/// - Requested encodings to activate are different than the currently activated ones.
/// - There is a running videoCapturingSession
final class AdaptiveVideoCapturePolicy: VideoCapturePolicy, @unchecked Sendable {

    @Injected(\.thermalStateObserver) private var thermalStateObserver

    private let neuralEngineExistsProvider: () -> Bool
    private var lastActiveEncodings: Set<String>?

    init(_ neuralEngineExistsProvider: @escaping () -> Bool) {
        self.neuralEngineExistsProvider = neuralEngineExistsProvider
        super.init()
    }

    /// Overrides the method to update capture quality using an adaptive policy.
    override func updateCaptureQuality(
        with activeEncodings: Set<String>,
        for activeSession: VideoCaptureSession?
    ) async throws {
        /// Ensure there is an active session to work with.
        guard
            shouldUpdateCaptureQuality,
            lastActiveEncodings != activeEncodings,
            let activeSession
        else { return }

        /// Filter the default video codecs to include only those matching the active encodings.
        let videoCodecs = VideoLayer
            .default
            .filter { activeEncodings.contains($0.quality.rawValue) }

        try await activeSession.capturer
            .updateCaptureQuality(videoCodecs, on: activeSession.device)
        lastActiveEncodings = activeEncodings
        log.debug(
            "Video capture quality adapted to [\(activeEncodings.sorted().joined(separator: ","))].",
            subsystems: .webRTC
        )
    }

    // MARK: - Private helpers

    private var shouldUpdateCaptureQuality: Bool {
        thermalStateObserver.state > .fair || !neuralEngineExistsProvider()
    }
}

extension VideoCapturePolicy {
    /// A video capture policy that does not adjust the capture quality based on SFU instructions.
    ///
    /// With this policy (`none`), the device continues to capture video at its initial quality settings,
    /// ignoring any requests from the SFU to adjust the quality. This may lead to unnecessary processing
    /// overhead, especially on less powerful devices, since the device may be capturing higher quality
    /// video than what is needed.
    static let none: VideoCapturePolicy = VideoCapturePolicy()

    /// A video capture policy that adapts the capture quality based on SFU instructions.
    ///
    /// This `adaptive` policy adjusts the device's video capture quality to match the quality requested
    /// by the SFU (Selective Forwarding Unit). By capturing video at the requested quality, it helps
    /// reduce processing overhead and improve performance, especially on older or less powerful devices.
    static let adaptive: VideoCapturePolicy = AdaptiveVideoCapturePolicy { neuralEngineExists }
}

extension VideoCapturePolicy: InjectionKey {
    /// The current video capture policy used for dependency injection.
    public static var currentValue: VideoCapturePolicy = .adaptive
}

extension InjectedValues {
    /// Accessor for the `videoCapturePolicy` in the injected values.
    var videoCapturePolicy: VideoCapturePolicy {
        get { Self[VideoCapturePolicy.self] }
        set { Self[VideoCapturePolicy.self] = newValue }
    }
}
