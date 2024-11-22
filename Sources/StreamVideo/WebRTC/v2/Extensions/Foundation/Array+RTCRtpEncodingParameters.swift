//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extension providing utilities for arrays of `RTCRtpEncodingParameters`.
extension Array where Element: RTCRtpEncodingParameters {

    /// Prepares the array of `RTCRtpEncodingParameters` for use with SVC codecs.
    ///
    /// This method adjusts the encoding parameters if a Scalable Video Codec (SVC)
    /// is being used. It filters the encodings to retain only the highest-quality
    /// layer (`.full`) and modifies its `rid` (Restriction Identifier) to use
    /// the lower-quality layer (`.quarter`) as required by certain SVC scenarios.
    ///
    /// - Parameter isSVC: A Boolean indicating whether an SVC codec is in use.
    /// - Returns: The modified array of `RTCRtpEncodingParameters` if SVC is used,
    ///   or the original array if SVC is not used.
    func prepareIfRequired(usesSVCCodec isSVC: Bool) -> Self {
        guard isSVC else {
            return self
        }

        // Filter for the highest-quality layer and adjust its `rid` if necessary.
        let rewriteResult = filter { $0.rid == VideoLayer.Quality.full.rawValue }
        rewriteResult.first?.rid = VideoLayer.Quality.quarter.rawValue

        return rewriteResult
    }
}
