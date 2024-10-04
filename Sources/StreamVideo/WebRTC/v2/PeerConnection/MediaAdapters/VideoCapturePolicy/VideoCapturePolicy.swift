//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

/// A class that defines a video capture policy.
public class VideoCapturePolicy: @unchecked Sendable {
    /// Initializes a new instance of `VideoCapturePolicy`.
    /// This initializer is `fileprivate` to restrict instantiation outside this file.
    fileprivate init() {}

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
private final class AdaptiveVideoCapturePolicy: VideoCapturePolicy, @unchecked Sendable {
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

        /// If a device is available in the active session, update its capture quality.
        if let device = activeSession.device {
            await activeSession.capturer
                .updateCaptureQuality(videoCodecs, on: device)
        }
    }
}

extension VideoCapturePolicy {
    /// A static instance representing a no-operation capture policy.
    static let none: VideoCapturePolicy = VideoCapturePolicy()

    /// A static instance of the adaptive video capture policy.
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
