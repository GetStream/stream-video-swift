//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Represents a unified, type-safe statistics processing unit for a single
/// WebRTC media track.
///
/// This structure is used by both encoder and decoder statistics transformers
/// to gather all relevant statistics about a video or screen-sharing track in
/// a single, type-safe container. It supports common properties required for
/// performance analytics, codec reporting, frame rate, resolution, and bitrate.
struct WebRTCItemTransformerProcessingUnit {
    /// The kind of the media track (e.g., "video", "audio").
    var kind: String

    /// The identifier of the codec used for this track.
    var codecId: String

    /// The total number of frames processed (sent or decoded).
    var frames: Int

    /// The frames per second reported for this track.
    var framesPerSecond: Int

    /// The total encode or decode time in seconds for this track.
    var totalTime: TimeInterval

    /// The track identifier, typically corresponding to a media source.
    var trackIdentifier: String

    /// The height (in pixels) of the video frame.
    var frameHeight: Int

    /// The width (in pixels) of the video frame.
    var frameWidth: Int

    /// The area (in pixels) of the video frame, calculated as width × height.
    var area: Int

    /// The ID of the associated media source for this track.
    var mediaSourceId: String

    /// The target bitrate for the track, if available (encoder only).
    var targetBitrate: Int?

    /// Initializes a new processing unit with all required properties.
    ///
    /// - Parameters match property names and represent extracted stat fields.
    private init(
        kind: String,
        codecId: String,
        frames: Int,
        framesPerSecond: Int,
        totalTime: TimeInterval,
        trackIdentifier: String,
        frameHeight: Int,
        frameWidth: Int,
        area: Int,
        mediaSourceId: String,
        targetBitrate: Int? = nil
    ) {
        self.kind = kind
        self.codecId = codecId
        self.frames = frames
        self.framesPerSecond = framesPerSecond
        self.totalTime = totalTime
        self.trackIdentifier = trackIdentifier
        self.frameHeight = frameHeight
        self.frameWidth = frameWidth
        self.area = area
        self.mediaSourceId = mediaSourceId
        self.targetBitrate = targetBitrate
    }
}

extension WebRTCItemTransformerProcessingUnit {

    /// Creates a processing unit from an encoder (outbound-rtp) RTCStatistics object.
    ///
    /// - Parameter stat: The RTCStatistics for the outbound track.
    /// - Returns: A populated processing unit for encoder stats.
    static func encoder(
        from stat: MutableRTCStatistics
    ) -> WebRTCItemTransformerProcessingUnit {
        .init(
            kind: stat.value(for: .kind, fallback: ""),
            codecId: stat.value(for: .codecId, fallback: ""),
            frames: stat.value(for: .framesSent, fallback: 0),
            framesPerSecond: stat.value(for: .framesPerSecond, fallback: 0),
            totalTime: stat.value(for: .totalEncodeTime, fallback: 0),
            trackIdentifier: "", // Fetched from mediaSource later
            frameHeight: stat.value(for: .frameHeight, fallback: 0),
            frameWidth: stat.value(for: .frameWidth, fallback: 0),
            area: stat.value(for: .frameWidth, fallback: 0) * stat.value(for: .frameHeight, fallback: 0),
            mediaSourceId: stat.value(for: .mediaSourceId, fallback: ""),
            targetBitrate: stat.value(for: .targetBitrate, fallback: 0)
        )
    }

    /// Creates a processing unit from a decoder (inbound-rtp) RTCStatistics object.
    ///
    /// - Parameter stat: The RTCStatistics for the inbound track.
    /// - Returns: A populated processing unit for decoder stats.
    static func decoder(
        from stat: MutableRTCStatistics
    ) -> WebRTCItemTransformerProcessingUnit {
        .init(
            kind: stat.value(for: .kind, fallback: ""),
            codecId: stat.value(for: .codecId, fallback: ""),
            frames: stat.value(for: .framesDecoded, fallback: 0),
            framesPerSecond: stat.value(for: .framesPerSecond, fallback: 0),
            totalTime: stat.value(for: .totalDecodeTime, fallback: 0),
            trackIdentifier: stat.value(for: .trackIdentifier, fallback: ""),
            frameHeight: stat.value(for: .frameHeight, fallback: 0),
            frameWidth: stat.value(for: .frameWidth, fallback: 0),
            area: stat.value(for: .frameWidth, fallback: 0) * stat.value(for: .frameHeight, fallback: 0),
            mediaSourceId: stat.value(for: .mediaSourceId, fallback: ""),
            targetBitrate: nil
        )
    }
}
