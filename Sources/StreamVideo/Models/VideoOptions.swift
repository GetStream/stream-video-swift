//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public struct VideoOptions {
    
    public var preferredFormat: AVCaptureDevice.Format?
    public var preferredDimensions: CMVideoDimensions
    public var preferredFps: Int
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

public struct VideoCodec {
    public let dimensions: CMVideoDimensions
    public let quality: String
    public let maxBitrate: Int
    public var scaleDownFactor: Int32?
}

extension VideoCodec {
    
    public static let defaultCodecs = [full, half, quarter]
    
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
