//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

/// Configuration for the video options for a call.
public struct VideoOptions: Sendable {
    
    /// The preferred video format.
    public var preferredFormat: AVCaptureDevice.Format?
    /// The preferred video dimensions.
    public var preferredDimensions: CMVideoDimensions
    /// The preferred frames per second.
    public var preferredFps: Int
    /// The supported codecs.
    public var supportedCodecs: [VideoCodec]
    
    public init(
        supportedCodecs: [VideoCodec] = VideoCodec.defaultCodecs,
        preferredFormat: AVCaptureDevice.Format? = nil,
        preferredDimensions: CMVideoDimensions = .full,
        preferredFps: Int = 30
    ) {
        self.preferredFormat = preferredFormat
        self.preferredDimensions = preferredDimensions
        self.preferredFps = preferredFps
        self.supportedCodecs = supportedCodecs
    }
}

/// Represents a video codec.
public struct VideoCodec: Sendable {
    /// The dimensions of the codec.
    public let dimensions: CMVideoDimensions
    /// The codec quality.
    public let quality: String
    /// The maximum bitrate.
    public let maxBitrate: Int
    /// Factor that tells how much the resolution should be scalled down.
    public var scaleDownFactor: Int32?
}

extension VideoCodec {
    
    public static let defaultCodecs = [quarter, half, full]
    
    static let full = VideoCodec(
        dimensions: .full,
        quality: "f",
        maxBitrate: 1_000_000
    )
    
    static let half = VideoCodec(
        dimensions: .half,
        quality: "h",
        maxBitrate: 500_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.half.area
    )
    
    static let quarter = VideoCodec(
        dimensions: .quarter,
        quality: "q",
        maxBitrate: 300_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.quarter.area
    )
}
