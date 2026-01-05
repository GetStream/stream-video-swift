//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation

/// Represents a video layer configuration.
///
/// Each `VideoLayer` defines properties such as dimensions, quality, bitrate,
/// and scaling factors for a particular video codec configuration, often used to handle different layers of
/// video streams (e.g., full, half, or quarter resolutions).
struct VideoLayer: Sendable {
    enum Quality: String {
        case full = "f"
        case half = "h"
        case quarter = "q"
    }

    /// The dimensions of the video layer.
    let dimensions: CMVideoDimensions
    /// A string representing the quality level of the video layer.
    let quality: Quality
    /// The maximum bitrate allowed for the video layer in bits per second.
    let maxBitrate: Int
    /// The factor by which the video resolution should be scaled down.
    var scaleDownFactor: Int32?

    /// The associated SFU (Selective Forwarding Unit) quality level.
    var sfuQuality: Stream_Video_Sfu_Models_VideoQuality

    /// A default set of video layers: quarter, half, and full.
    static let `default` = [quarter, half, full]

    /// Full resolution video layer configuration.
    static let full = VideoLayer(
        dimensions: .full,
        quality: .full,
        maxBitrate: .maxBitrate,
        sfuQuality: .high
    )

    /// Half resolution video layer configuration.
    static let half = VideoLayer(
        dimensions: .half,
        quality: .half,
        maxBitrate: 500_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.half.area,
        sfuQuality: .mid
    )

    /// Quarter resolution video layer configuration.
    static let quarter = VideoLayer(
        dimensions: .quarter,
        quality: .quarter,
        maxBitrate: 300_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.quarter.area,
        sfuQuality: .lowUnspecified
    )

    /// Video layer configuration for screen sharing.
    static let screenshare = VideoLayer(
        dimensions: .full,
        quality: .quarter,
        maxBitrate: .maxBitrate,
        sfuQuality: .high
    )
}
