//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

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
    ) async { /* No operation by default */ }
}

/// A final class that adapts the video capture quality dynamically.
final class AdaptiveVideoCapturePolicy: VideoCapturePolicy, @unchecked Sendable {
    /// Overrides the method to update capture quality using an adaptive policy.
    override func updateCaptureQuality(
        with activeEncodings: Set<String>,
        for activeSession: VideoCaptureSession?
    ) async {
        /// Ensure there is an active session to work with.
        guard let activeSession else { return }

        /// Filter the default video codecs to include only those matching the active encodings.
        let videoCodecs = VideoCodec
            .defaultCodecs
            .filter { activeEncodings.contains($0.quality) }

        await activeSession.capturer
            .updateCaptureQuality(videoCodecs, on: activeSession.device)
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
    static let adaptive: VideoCapturePolicy = AdaptiveVideoCapturePolicy()
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
