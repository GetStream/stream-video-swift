//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Extension adding a convenience initializer for `Stream_Video_Sfu_Models_VideoQuality`.
extension Stream_Video_Sfu_Models_VideoQuality {

    /// Initializes a `Stream_Video_Sfu_Models_VideoQuality` from a `VideoLayer.Quality`.
    ///
    /// This initializer maps the `VideoLayer.Quality` levels to their corresponding
    /// `Stream_Video_Sfu_Models_VideoQuality` values, ensuring compatibility between
    /// the two models.
    ///
    /// - Parameter source: The `VideoLayer.Quality` value to convert.
    ///
    /// - Mapping:
    ///   - `.full` maps to `.high`.
    ///   - `.half` maps to `.mid`.
    ///   - `.quarter` maps to `.lowUnspecified`.
    init(_ source: VideoLayer.Quality) {
        switch source {
        case .full:
            self = .high
        case .half:
            self = .mid
        case .quarter:
            self = .lowUnspecified
        }
    }
}
