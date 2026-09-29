//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public final class VideoConfig: Sendable {
    /// An array of `VideoFilter` objects representing the filters to apply to the video.
    public let videoFilters: [VideoFilter]

    /// The noiseCancellationFilter that StreamVideo will use when call noiseCancellation settings
    /// require automatic handling (e.g. when the mode is set to `autoOn`).
    public let noiseCancellationFilter: NoiseCancellationFilter?

    /// The audio processing module that handles the audio streams provided by WebRTC.
    public let audioProcessingModule: AudioProcessingModule

    /// Enables the capture-time processing pipeline for video filters.
    /// Enables the capture-time processing pipeline (e.g., filter nodes).
    public let usesProcessingPipeline: Bool
    public let usesNewCapturingPipeline: Bool

    /// Caller-side polling for the ring outcome, used when the
    /// `call.accepted`, `call.rejected` or `call.missed` event never
    /// arrives. On by default; `nil` turns it off.
    public let ringStatePolling: RingStatePollingOptions?

    /// Initializes a new instance of `VideoConfig` with the specified parameters.
    /// - Parameters:
    ///   - videoFilters: An array of `VideoFilter` objects representing the filters to apply to the video.
    ///   - noiseCancellationFilter: An ``NoiseCancellationFilter`` object representing the
    ///   noiseCancellationFilter, that the SDK will use whenever noiseCancellation handling requires
    ///   automatic actions (e.g. when the NoiseCancellationSettings.mode is set to `autoOn`).
    ///   - audioProcessingModule: Provide your own audio processing or fallback to the
    ///     default one.
    ///   - usesProcessingPipeline: Enables capture-time processing for camera frames.
    ///   - ringStatePolling: Timings for polling the outcome of a ring the
    ///     current user started. Pass `nil` to turn polling off.
    /// - Returns: A new instance of `VideoConfig`.
    public init(
        videoFilters: [VideoFilter] = [],
        noiseCancellationFilter: NoiseCancellationFilter? = nil,
        audioProcessingModule: AudioProcessingModule? = nil,
        usesProcessingPipeline: Bool = true,
        usesNewCapturingPipeline: Bool = true,
        ringStatePolling: RingStatePollingOptions? = .init()
    ) {
        self.videoFilters = videoFilters
        self.noiseCancellationFilter = noiseCancellationFilter
        self.audioProcessingModule = audioProcessingModule ?? InjectedValues[\.audioFilterProcessingModule]
        self.usesProcessingPipeline = usesProcessingPipeline
        self.usesNewCapturingPipeline = usesNewCapturingPipeline
        self.ringStatePolling = ringStatePolling
    }
}

/// Timings for polling the outcome of a ring the current user started.
public struct RingStatePollingOptions: Sendable, Equatable {
    /// Quiet time after the ring starts, or after the last ring event,
    /// before the first poll.
    public var startAfter: TimeInterval
    /// The time between polls.
    public var interval: TimeInterval

    /// The defaults match the JS and Android SDKs.
    public init(startAfter: TimeInterval = 15, interval: TimeInterval = 5) {
        self.startAfter = startAfter
        self.interval = interval
    }
}
