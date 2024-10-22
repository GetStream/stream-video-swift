//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation

/// Represents a video codec.
struct VideoLayer: Sendable {
    /// The dimensions of the codec.
    let dimensions: CMVideoDimensions
    /// The codec quality.
    let quality: String
    /// The maximum bitrate.
    let maxBitrate: Int
    /// Factor that tells how much the resolution should be scaled down.
    var scaleDownFactor: Int32?
    
    var sfuQuality: Stream_Video_Sfu_Models_VideoQuality
    
    static let `default` = [quarter, half, full]

    static let full = VideoLayer(
        dimensions: .full,
        quality: "f",
        maxBitrate: .maxBitrate,
        sfuQuality: .high
    )
    
    static let half = VideoLayer(
        dimensions: .half,
        quality: "h",
        maxBitrate: 500_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.half.area,
        sfuQuality: .mid
    )
    
    static let quarter = VideoLayer(
        dimensions: .quarter,
        quality: "q",
        maxBitrate: 300_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.quarter.area,
        sfuQuality: .lowUnspecified
    )
    
    static let screenshare = VideoLayer(
        dimensions: .full,
        quality: "q",
        maxBitrate: .maxBitrate,
        sfuQuality: .high
    )
}
