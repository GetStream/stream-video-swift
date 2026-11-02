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

    /// Polls outgoing ring outcomes when events are lost.
    /// Enabled by default; `nil` disables polling.
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
    ///   - ringStatePolling: Outgoing ring polling options; `nil` disables it.
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

/// Timings for polling outgoing ring outcomes.
public struct RingStatePollingOptions: Sendable, Equatable {
    /// Seconds of silence after ringing or the last outcome before polling.
    public var startAfter: TimeInterval
    /// Seconds between polls.
    public var interval: TimeInterval

    /// Defaults to polling after 9 seconds of silence, every 5 seconds.
    public init(startAfter: TimeInterval = 9, interval: TimeInterval = 5) {
        self.startAfter = startAfter
        self.interval = interval
    }
}
