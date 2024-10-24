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
    var preferredVideoCodec: VideoCodec
    var preferredBitrate: Int
    var preferredTargetResolution: TargetResolution?
    var preferredCameraPosition: AVCaptureDevice.Position

    /// The supported codecs.
    var videoLayers: [VideoLayer]

    init(
        preferredTargetResolution: TargetResolution? = nil,
        preferredFormat: AVCaptureDevice.Format? = nil,
        preferredFps: Int = 30,
        preferredVideoCodec: VideoCodec = .h264,
        preferredBitrate: Int = .maxBitrate,
        preferredCameraPosition: AVCaptureDevice.Position = .front
    ) {
        self.preferredTargetResolution = preferredTargetResolution
        self.preferredFormat = preferredFormat
        self.preferredFps = preferredFps
        self.preferredVideoCodec = preferredVideoCodec
        self.preferredBitrate = preferredBitrate
        self.preferredCameraPosition = preferredCameraPosition

        if let preferredTargetResolution {
            preferredDimensions = CMVideoDimensions(
                width: Int32(preferredTargetResolution.width),
                height: Int32(preferredTargetResolution.height)
            )
            do {
                videoLayers = try VideoCapturingUtils.codecs(
                    preferredFormat: preferredFormat,
                    preferredDimensions: preferredDimensions,
                    preferredFps: preferredFps,
                    preferredBitrate: preferredTargetResolution.bitrate ?? preferredBitrate,
                    preferredCameraPosition: preferredCameraPosition
                )
            } catch {
                videoLayers = VideoLayer.default
            }
        } else {
            preferredDimensions = .full
            videoLayers = VideoLayer.default
        }

        print("")
    }

    func with(preferredTargetResolution: TargetResolution?) -> VideoOptions {
        .init(
            preferredTargetResolution: preferredTargetResolution,
            preferredFormat: preferredFormat,
            preferredFps: preferredFps,
            preferredVideoCodec: preferredVideoCodec,
            preferredBitrate: preferredBitrate,
            preferredCameraPosition: preferredCameraPosition
        )
    }

    func with(preferredVideoCodec: VideoCodec) -> VideoOptions {
        .init(
            preferredTargetResolution: preferredTargetResolution,
            preferredFormat: preferredFormat,
            preferredFps: preferredFps,
            preferredVideoCodec: preferredVideoCodec,
            preferredBitrate: preferredBitrate,
            preferredCameraPosition: preferredCameraPosition
        )
    }

    func with(preferredBitrate: Int) -> VideoOptions {
        .init(
            preferredTargetResolution: preferredTargetResolution,
            preferredFormat: preferredFormat,
            preferredFps: preferredFps,
            preferredVideoCodec: preferredVideoCodec,
            preferredBitrate: preferredBitrate,
            preferredCameraPosition: preferredCameraPosition
        )
    }

    func with(preferredCameraPosition: AVCaptureDevice.Position) -> VideoOptions {
        .init(
            preferredTargetResolution: preferredTargetResolution,
            preferredFormat: preferredFormat,
            preferredFps: preferredFps,
            preferredVideoCodec: preferredVideoCodec,
            preferredBitrate: preferredBitrate,
            preferredCameraPosition: preferredCameraPosition
        )
    }
}

extension Int {
    public static let maxBitrate = 1_000_000
}
