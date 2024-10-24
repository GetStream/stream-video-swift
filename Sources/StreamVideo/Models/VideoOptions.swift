//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamWebRTC

/// Configuration for the video options for a call.
struct VideoOptions: Sendable {
    
    /// The preferred video format.
    var preferredFormat: AVCaptureDevice.Format?
    /// The preferred video dimensions.
    var preferredDimensions: CMVideoDimensions
    /// The preferred frames per second.
    var preferredFps: Int
    /// The supported codecs.
    var supportedCodecs: [VideoCodec]
    
    init(
        targetResolution: TargetResolution? = nil,
        preferredFormat: AVCaptureDevice.Format? = nil,
        preferredFps: Int = 30
    ) {
        self.preferredFormat = preferredFormat
        self.preferredFps = preferredFps
        if let targetResolution {
            preferredDimensions = CMVideoDimensions(
                width: Int32(targetResolution.width),
                height: Int32(targetResolution.height)
            )
            do {
                supportedCodecs = try VideoCapturingUtils.codecs(
                    preferredFormat: preferredFormat,
                    preferredDimensions: preferredDimensions,
                    preferredFps: preferredFps,
                    preferredBitrate: targetResolution.bitrate ?? .maxBitrate
                )
            } catch {
                supportedCodecs = VideoCodec.defaultCodecs
            }
        } else {
            preferredDimensions = .full
            supportedCodecs = VideoCodec.defaultCodecs
        }
    }
}

/// Represents a video codec.
struct VideoCodec: Sendable {
    /// The dimensions of the codec.
    let dimensions: CMVideoDimensions
    /// The codec quality.
    let quality: String
    /// The maximum bitrate.
    let maxBitrate: Int
    /// Factor that tells how much the resolution should be scalled down.
    var scaleDownFactor: Int32?
    
    var sfuQuality: Stream_Video_Sfu_Models_VideoQuality
}

extension VideoCodec {
    
    static let defaultCodecs = [quarter, half, full]
    
    static let full = VideoCodec(
        dimensions: .full,
        quality: "f",
        maxBitrate: .maxBitrate,
        sfuQuality: .high
    )
    
    static let half = VideoCodec(
        dimensions: .half,
        quality: "h",
        maxBitrate: 500_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.half.area,
        sfuQuality: .mid
    )
    
    static let quarter = VideoCodec(
        dimensions: .quarter,
        quality: "q",
        maxBitrate: 300_000,
        scaleDownFactor: CMVideoDimensions.full.area / CMVideoDimensions.quarter.area,
        sfuQuality: .lowUnspecified
    )
    
    static let screenshare = VideoCodec(
        dimensions: .full,
        quality: "q",
        maxBitrate: .maxBitrate,
        sfuQuality: .high
    )
}

extension Int {
    static let maxBitrate = 1_000_000
}
