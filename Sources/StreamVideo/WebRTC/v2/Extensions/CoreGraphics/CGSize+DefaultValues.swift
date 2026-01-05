//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import CoreMedia
import Foundation

/// Extension providing default video dimensions and utility methods for `CGSize`.
extension CGSize {
    /// Default dimensions for full quality video.
    ///
    /// Used for video layers with ``VideoLayer.Quality.full``.
    static let full = CGSize(width: 1280, height: 720)

    /// Default dimensions for half quality video.
    ///
    /// Used for video layers with ``VideoLayer.Quality.half``.
    static let half = CGSize(width: 640, height: 480)

    /// Default dimensions for quarter quality video.
    ///
    /// Used for video layers with ``VideoLayer.Quality.quarter``.
    static let quarter = CGSize(width: 480, height: 360)

    /// The total area of the `CGSize`, calculated as `width * height`.
    var area: CGFloat { width * height }

    /// Initializes a `CGSize` from a `CMVideoDimensions` source.
    ///
    /// - Parameter source: The `CMVideoDimensions` containing width and height values.
    /// - Converts the `CMVideoDimensions` values to `CGFloat` and assigns them to `CGSize`.
    init(_ source: CMVideoDimensions) {
        self = .init(
            width: CGFloat(source.width),
            height: CGFloat(source.height)
        )
    }
}
