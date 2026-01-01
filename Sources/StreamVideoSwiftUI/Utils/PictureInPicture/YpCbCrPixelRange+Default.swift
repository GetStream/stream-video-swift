//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Accelerate
import Foundation

/// Extension of vImage_YpCbCrPixelRange to include a default configuration.
extension vImage_YpCbCrPixelRange {

    /// Initializes a default pixel range for YpCbCr pixel format.
    /// This default configuration is often used when converting YpCbCr to RGB.
    /// - Yp_bias: The bias for the Y' (luma) component, typically 0.
    /// - CbCr_bias: The bias for the Cb and Cr (chroma) components, usually set to 128 to center the chroma values.
    /// - YpRangeMax: The maximum value for the Y' range, typically 255.
    /// - CbCrRangeMax: The maximum value for the Cb and Cr range, also usually 255.
    /// - YpMax: The maximum possible value for Y', generally 255.
    /// - YpMin: The minimum possible value for Y', usually set to 1 for video ranges.
    /// - CbCrMax: The maximum possible value for Cb and Cr, typically 255.
    /// - CbCrMin: The minimum possible value for Cb and Cr, often 0.
    /// Reference: [Apple's documentation on vImageConvert_YpCbCrToARGB](https://developer.apple.com/documentation/accelerate/1533189-vimageconvert_ypcbcrtoargb_gener)
    static let `default` = vImage_YpCbCrPixelRange(
        Yp_bias: 0, /// The bias applied to the Y' component.
        CbCr_bias: 128, /// The bias applied to the Cb and Cr components.
        YpRangeMax: 255, /// The maximum value of the Y' range.
        CbCrRangeMax: 255, /// The maximum value of the Cb and Cr range.
        YpMax: 255, /// The maximum value of Y'.
        YpMin: 1, /// The minimum value of Y' (often used for setting video range).
        CbCrMax: 255, /// The maximum value of Cb and Cr.
        CbCrMin: 0 /// The minimum value of Cb and Cr.
    )
}
