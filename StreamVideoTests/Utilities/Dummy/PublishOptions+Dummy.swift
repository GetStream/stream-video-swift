//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension PublishOptions {
    static func dummy(
        audio: [AudioPublishOptions] = [],
        video: [VideoPublishOptions] = [],
        screenShare: [VideoPublishOptions] = []
    ) -> PublishOptions {
        .init(
            audio: audio,
            video: video,
            screenShare: screenShare
        )
    }
}

extension PublishOptions.AudioPublishOptions {
    static func dummy(
        id: Int = 0,
        codec: AudioCodec,
        bitrate: Int = 0
    ) -> PublishOptions.AudioPublishOptions {
        .init(
            id: id,
            codec: codec,
            bitrate: bitrate
        )
    }
}

extension PublishOptions.VideoPublishOptions {
    static func dummy(
        id: Int = 0,
        codec: VideoCodec,
        fmtp: String = .unique,
        capturingLayers: PublishOptions.VideoPublishOptions.CapturingLayers = .init(
            spatialLayers: .maxSpatialLayers,
            temporalLayers: .maxTemporalLayers
        ),
        bitrate: Int = .maxBitrate,
        frameRate: Int = .defaultFrameRate,
        dimensions: CGSize = .full
    ) -> PublishOptions.VideoPublishOptions {
        .init(
            id: id,
            codec: codec,
            fmtp: fmtp,
            capturingLayers: capturingLayers,
            bitrate: bitrate,
            frameRate: frameRate,
            dimensions: dimensions
        )
    }
}
