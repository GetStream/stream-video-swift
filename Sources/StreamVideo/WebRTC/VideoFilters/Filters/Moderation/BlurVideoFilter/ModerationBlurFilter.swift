//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage
import Foundation

/// A video filter that applies a strong Gaussian blur to the entire frame,
/// suitable for content moderation (e.g. hiding NSFW content).
///
public final class ModerationBlurVideoFilter: VideoFilter, @unchecked Sendable {
    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) { fatalError() }

    /// Creates a blur filter that hides the entire frame for moderation needs.
    /// - Parameters:
    ///   - blurRadius: Radius for the Gaussian blur.
    ///   - downscaleFactor: Downscale applied before blur for performance.
    public init(
        blurRadius: CGFloat = 25,
        downscaleFactor: CGFloat = 0.5
    ) {
        let clampedDownscale = max(min(downscaleFactor, 1), 0.1)
        let radius = blurRadius
        let name = String(describing: type(of: self)).lowercased()

        super.init(
            id: "io.getstream.\(name)",
            name: name,
            filter: { input in
                let srcImage = input.originalImage
                let extent = srcImage.extent

                // Optional downscale before blur for better performance.
                let workingImage: CIImage
                if clampedDownscale < 1 {
                    workingImage = srcImage.transformed(
                        by: CGAffineTransform(
                            scaleX: clampedDownscale,
                            y: clampedDownscale
                        )
                    )
                } else {
                    workingImage = srcImage
                }

                // Clamp to avoid edge transparency, then blur.
                let clamped = workingImage.clampedToExtent()

                let blur = CIFilter.gaussianBlur()
                blur.inputImage = clamped
                blur.radius = Float(radius)

                guard var blurred = blur.outputImage else {
                    // Fallback: return original image if filter fails.
                    return srcImage
                }

                // If we downscaled, scale back up to original size.
                if clampedDownscale < 1 {
                    let scaleBack = 1 / clampedDownscale
                    blurred = blurred.transformed(
                        by: CGAffineTransform(
                            scaleX: scaleBack,
                            y: scaleBack
                        )
                    )
                }

                // Crop to original extent to avoid any clamping artifacts.
                return blurred.cropped(to: extent)
            }
        )
    }
}
