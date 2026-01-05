//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation

extension Stream_Video_Sfu_Models_PublishOption {

    /// Generates an array of video layers based on the publish option's dimensions and bitrate.
    ///
    /// - Parameter qualities: An array of `VideoLayer.Quality` values representing the desired
    ///   quality levels for the video layers. Defaults to `[.full, .half, .quarter]`.
    /// - Returns: An array of `VideoLayer` instances, ordered from lowest quality to highest.
    ///
    /// ## Overview
    /// This method creates video layers by progressively scaling down the base video dimensions
    /// and bitrate for each quality level provided. The resulting layers are optimized for
    /// streaming environments, enabling adaptive video quality based on network conditions.
    ///
    /// ## Example
    /// ```swift
    /// let publishOption = Stream_Video_Sfu_Models_PublishOption(
    ///     videoDimension: CMVideoDimensions(width: 1920, height: 1080),
    ///     bitrate: 4000
    /// )
    /// let videoLayers = publishOption.videoLayers()
    /// print(videoLayers) // [Quarter, Half, Full]
    /// ```
    ///
    /// ## Notes
    /// - The method assumes that lower-quality layers are created by halving the dimensions
    ///   and bitrate for each successive quality level.
    /// - The layers are returned in reverse order to prioritize lower-quality layers first.
    func videoLayers(
        spatialLayersRequired: Int
    ) -> [VideoLayer] {
        // Extract base dimensions and bitrate from the publish option.
        let publishOptionWidth = Int(videoDimension.width)
        let publishOptionHeight = Int(videoDimension.height)
        let publishOptionBitrate = Int(bitrate)

        // Initialize the scale-down factor for progressive quality reduction.
        var scaleDownFactor: Int = 1

        // Array to hold the generated video layers.
        let qualities: [VideoLayer.Quality] = [.full, .half, .quarter]
        var videoLayers: [VideoLayer] = []
        for quality in qualities {
            // Calculate dimensions and bitrate for the current quality level.
            let width = publishOptionWidth / scaleDownFactor
            let height = publishOptionHeight / scaleDownFactor
            let bitrate = publishOptionBitrate / Int(scaleDownFactor)
            let dimensions = CMVideoDimensions(width: Int32(width), height: Int32(height))

            // Create a new video layer and append it to the array.
            let videoLayer = VideoLayer(
                dimensions: dimensions,
                quality: quality,
                maxBitrate: bitrate,
                sfuQuality: .init(quality)
            )

            videoLayers.append(videoLayer)
            // Double the scale-down factor for the next quality level.
            scaleDownFactor *= 2
        }

        if spatialLayersRequired < 3 {
            let unnecessaryLayers = videoLayers.count - spatialLayersRequired
            // We start removing from the lowest qualities that are at the end.
            videoLayers = videoLayers.dropLast(unnecessaryLayers)
        }

        return videoLayers
    }
}
