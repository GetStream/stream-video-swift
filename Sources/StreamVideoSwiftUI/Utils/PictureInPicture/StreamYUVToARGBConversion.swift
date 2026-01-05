//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@preconcurrency import Accelerate
import Foundation

/// A class dedicated to converting YUV (YpCbCr) image data to ARGB format.
final class StreamYUVToARGBConversion {

    /// Enum defining the color conversion coefficients for YUV to ARGB conversion.
    ///
    /// The coefficient in the context of `vImageConvert_YpCbCrToARGB_GenerateConversion`
    /// refers to a set of values used to define the color conversion matrix when transforming YpCbCr pixel
    /// format images to ARGB format. This conversion is crucial in image and video processing where color
    /// space compatibility is necessary for various rendering, compositing, or display purposes.
    ///
    /// Understanding YpCbCr to ARGB Conversion YpCbCr is a color space used in video compression
    /// and broadcasting, where Yp represents the luma component (the brightness), and Cb and Cr
    /// represent the chroma components (the color details). Converting YpCbCr to ARGB (Alpha, Red, Green, Blue)
    /// involves transforming these components into a format commonly used in digital images, which
    /// includes separate channels for red, green, blue, and an alpha transparency channel.
    ///
    /// Role of the Coefficient
    /// - Color Space Transformation: The coefficients are used to create a matrix that mathematically
    /// transforms the YpCbCr values into RGB values. This matrix accounts for the differences in color
    /// representation between the two formats, ensuring accurate color rendition.
    ///
    /// - Handling Various Standards: Different video standards (like ITU-R BT.601, ITU-R BT.709, etc.)
    /// define different coefficients because they assume different color primaries (red, green, and blue points)
    /// and different luma/chroma formulations. The coefficient matrix you choose should match the standard
    /// used when the YpCbCr data was originally created to ensure color accuracy.
    ///
    /// - Performance Optimization: Using a precalculated conversion matrix (which the coefficients help define)
    /// allows for highly optimized, performant image processing. This is critical in real-time applications,
    /// like video playback or editing, where processing speed is crucial.
    ///
    /// - Adjusting Luminance and Chrominance: The coefficients can also adjust the scale and bias of the
    /// luminance (Yp) and chrominance (Cb and Cr) to match the expected range of the ARGB format.
    /// This is essential for maintaining the correct brightness, contrast, and color saturation in the
    /// converted image.
    ///
    /// Usage in `vImageConvert_YpCbCrToARGB_GenerateConversion`
    /// When you use `vImageConvert_YpCbCrToARGB_GenerateConversion`, you typically provide a
    /// `vImage_YpCbCrToARGB` structure that includes the coefficients. The function then uses these
    /// coefficients to populate the structure with the necessary data to perform the conversion efficiently.
    /// The populated structure can subsequently be used with other vImage functions to convert image
    /// buffers from YpCbCr to ARGB.
    ///
    /// The correct selection and use of the coefficient matrix are vital for achieving accurate color conversion,
    /// maintaining image quality, and ensuring consistency across various processing stages or devices.
    /// The ability to specify different coefficients makes the vImage framework flexible and capable of
    /// handling various video standards and custom conversion needs.
    ///
    /// - Parameters:
    ///     - YpCbCrToARGBMatrix_ITU_R_601_4: ITU-R Recommendation BT.601, often used for
    ///     standard-definition television.
    ///     - YpCbCrToARGBMatrix_ITU_R_709_2: ITU-R Recommendation BT.709, often used for
    ///     high-definition television.
    enum Coefficient: @unchecked Sendable {
        /// ITU-R Recommendation BT.601, often used for standard-definition video.
        case YpCbCrToARGBMatrix_ITU_R_601_4

        /// ITU-R Recommendation BT.709, often used for high-definition video.
        case YpCbCrToARGBMatrix_ITU_R_709_2

        /// Computed property to provide a pointer to the relevant conversion matrix.
        ///
        /// - Returns: A pointer to the selected color conversion matrix.
        var value: UnsafePointer<vImage_YpCbCrToARGBMatrix> {
            switch self {
            case .YpCbCrToARGBMatrix_ITU_R_601_4: return kvImage_YpCbCrToARGBMatrix_ITU_R_601_4
            case .YpCbCrToARGBMatrix_ITU_R_709_2: return kvImage_YpCbCrToARGBMatrix_ITU_R_709_2
            }
        }
    }

    /// The pixel range configuration for YUV to ARGB conversion, defaulting to standard range.
    private var pixelRange: vImage_YpCbCrPixelRange

    /// The coefficient matrix to use, defaulting to ITU-R BT.601.
    private var coefficient: Coefficient

    /// The type of YpCbCr pixel data, default set to a common format.
    private var inYpCbCrType: vImageYpCbCrType

    /// The output ARGB pixel format, default set to 8 bits per channel.
    private var outARGBType: vImageARGBType

    /// Flags for the conversion process, with no flags set by default.
    private var flags: UInt32

    /// The resulting conversion object to be used for converting YUV to ARGB.
    var output: vImage_YpCbCrToARGB

    /// Initializes the conversion setup with optional custom parameters.
    ///
    /// - Parameters:
    ///   - pixelRange: The pixel range configuration, defaulting to `.default`.
    ///   - coefficient: The coefficient matrix to use, defaulting to `.YpCbCrToARGBMatrix_ITU_R_601_4`.
    ///   - inYpCbCrType: The type of YpCbCr pixel data, default set to `kvImage420Yp8_Cb8_Cr8`.
    ///   - outARGBType: The output ARGB pixel format, default set to `kvImageARGB8888`.
    ///   - flags: Flags for the conversion process, with no flags set by default.
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

        /// Generates a conversion setup for converting YpCbCr to ARGB using specified parameters.
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
