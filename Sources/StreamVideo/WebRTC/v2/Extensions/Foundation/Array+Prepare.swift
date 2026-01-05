//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    func prepare() -> Self {
        enumerated()
            .map {
                switch $0.offset {
                case 0:
                    $0.element.rid = VideoLayer.Quality.quarter.rawValue
                case 1:
                    $0.element.rid = VideoLayer.Quality.half.rawValue
                case 2:
                    $0.element.rid = VideoLayer.Quality.full.rawValue
                default:
                    break
                }
                return $0.element
            }
    }
}

extension Array where Element == Stream_Video_Sfu_Models_VideoLayer {

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
    func prepare() -> Self {
        enumerated()
            .map { (offset, element) in
                var element = element
                switch offset {
                case 0:
                    element.rid = VideoLayer.Quality.quarter.rawValue
                case 1:
                    element.rid = VideoLayer.Quality.half.rawValue
                case 2:
                    element.rid = VideoLayer.Quality.full.rawValue
                default:
                    break
                }
                return element
            }
    }
}
