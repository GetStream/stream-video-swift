//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Accelerate
import Foundation

extension vImage_YpCbCrPixelRange {

    /// Reference https://developer.apple.com/documentation/accelerate/1533189-vimageconvert_ypcbcrtoargb_gener
    static let `default` = vImage_YpCbCrPixelRange(
        Yp_bias: 0,
        CbCr_bias: 128,
        YpRangeMax: 255,
        CbCrRangeMax: 255,
        YpMax: 255,
        YpMin: 1,
        CbCrMax: 255,
        CbCrMin: 0
    )
}
