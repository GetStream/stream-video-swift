//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import CoreImage
import Foundation

/// Applies a pixelation effect to fully obfuscate a frame.
public final class ModerationPixelateVideoFilter: VideoFilter, @unchecked Sendable {
    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) { fatalError() }

    /// Creates a moderation pixelation filter.
    /// - Parameters:
    ///   - pixelBlockFactor: Larger values create bigger pixel blocks.
    ///   - downscaleFactor: Downscale before pixelation to boost performance.
    public init(
        pixelBlockFactor: CGFloat = 40,
        downscaleFactor: CGFloat = 0.5
    ) {
        let clampedDownscale = max(min(downscaleFactor, 1), 0.1)
        let blockFactor = max(pixelBlockFactor, 1)
        let name = String(describing: type(of: self)).lowercased()

        super.init(
            id: "io.getstream.\(name)",
            name: name,
            filter: { input in
                let srcImage = input.originalImage
                let extent = srcImage.extent

                // Optional downscale before pixelation for better performance.
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

                let workingExtent = workingImage.extent

                let pixelate = CIFilter.pixellate()
                pixelate.inputImage = workingImage

                // Big cells -> heavy censorship, size-aware.
                let maxDimension = max(workingExtent.width, workingExtent.height)
                pixelate.scale = Float(maxDimension / blockFactor)

                guard var out = pixelate.outputImage else {
                    return srcImage
                }

                // If we downscaled, scale back up to original size.
                if clampedDownscale < 1 {
                    let scaleBack = 1 / clampedDownscale
                    out = out.transformed(
                        by: CGAffineTransform(
                            scaleX: scaleBack,
                            y: scaleBack
                        )
                    )
                }

                // Crop to original extent to avoid any edge artifacts.
                return out.cropped(to: extent)
            }
        )
    }
}
