//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides default values for frame rate and bitrate.
extension Int {
    /// The default frame rate for video streams.
    ///
    /// Typically used for video publishing when no specific frame rate is set.
    public static let defaultFrameRate: Int = 30

    /// The default frame rate for screenShare streams.
    public static let defaultScreenShareFrameRate: Int = 25

    /// The maximum bitrate for video streams, in bits per second.
    ///
    /// Used to limit the data rate for video publishing to optimize quality
    /// and bandwidth usage.
    public static let maxBitrate = 1_000_000

    /// The maximum number of spatial layers for video streams.
    ///
    /// Spatial layers are used in scalable video encoding to allow the receiver
    /// to adapt to varying network conditions or device capabilities.
    public static let maxSpatialLayers = 3

    /// The maximum number of temporal layers for video streams.
    ///
    /// Temporal layers allow for frame rate scalability in video streams, enabling
    /// smoother playback or reduced data usage on low-bandwidth connections.
    public static let maxTemporalLayers = 1
}
