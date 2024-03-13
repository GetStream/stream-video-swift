//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Accelerate
import Foundation

final class StreamYUVToARGBConversion {
    enum Coefficient {
        case YpCbCrToARGBMatrix_ITU_R_601_4
        case YpCbCrToARGBMatrix_ITU_R_709_2

        var value: UnsafePointer<vImage_YpCbCrToARGBMatrix> {
            switch self {
            case .YpCbCrToARGBMatrix_ITU_R_601_4:
                return kvImage_YpCbCrToARGBMatrix_ITU_R_601_4
            case .YpCbCrToARGBMatrix_ITU_R_709_2:
                return kvImage_YpCbCrToARGBMatrix_ITU_R_709_2
            }
        }
    }

    private var pixelRange: vImage_YpCbCrPixelRange = .default
    private var coefficient: Coefficient = .YpCbCrToARGBMatrix_ITU_R_601_4
    private var inYpCbCrType: vImageYpCbCrType = kvImage420Yp8_Cb8_Cr8
    private var outARGBType: vImageARGBType = kvImageARGB8888
    private var flags: UInt32 = UInt32(kvImageNoFlags)

    var output: vImage_YpCbCrToARGB

    init(
        pixelRange: vImage_YpCbCrPixelRange = .default,
        coefficient: Coefficient = .YpCbCrToARGBMatrix_ITU_R_601_4,
        inYpCbCrType: vImageYpCbCrType = kvImage420Yp8_Cb8_Cr8,
        outARGBType: vImageARGBType = kvImageARGB8888,
        flags: UInt32 = UInt32(kvImageNoFlags)
    ) {
        self.pixelRange = pixelRange
        self.coefficient = coefficient
        self.inYpCbCrType = inYpCbCrType
        self.outARGBType = outARGBType
        self.flags = flags
        output = vImage_YpCbCrToARGB()

        vImageConvert_YpCbCrToARGB_GenerateConversion(
            self.coefficient.value,
            &self.pixelRange,
            &output,
            inYpCbCrType,
            outARGBType,
            flags
        )
    }
}
