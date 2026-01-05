//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation

/// Extension providing default video dimensions and utility methods for `CMVideoDimensions`.
extension CMVideoDimensions {

    /// Represents full quality video dimensions (1280x720).
    ///
    /// Used for video layers with ``VideoLayer.Quality.full``.
    public static let full = CMVideoDimensions(.full)

    /// Represents half quality video dimensions (640x480).
    ///
    /// Used for video layers with ``VideoLayer.Quality.half``.
    public static let half = CMVideoDimensions(.half)

    /// Represents quarter quality video dimensions (480x360).
    ///
    /// Used for video layers with ``VideoLayer.Quality.quarter``.
    public static let quarter = CMVideoDimensions(.quarter)

    /// The total area of the video dimensions, calculated as `width * height`.
    ///
    /// - Returns: The area of the dimensions as an `Int32`.
    var area: Int32 { width * height }

    /// Initializes a `CMVideoDimensions` instance from a `CGSize`.
    ///
    /// - Parameter source: The `CGSize` containing width and height values.
    /// - Converts the `CGSize` dimensions into the required `Int32` format.
    init(_ source: CGSize) {
        self = .init(
            width: Int32(source.width),
            height: Int32(source.height)
        )
    }
}
