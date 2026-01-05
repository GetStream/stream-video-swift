//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import CoreImage
import Foundation

/// A video filter that applies a Gaussian blur to the background of the input video.
///
/// This filter uses a separate background image created by applying a Gaussian blur
/// to the original frame. It then combines the blurred background with the original
/// foreground objects using a filter processor, which extracts the person in the provided image and overlay
/// them over the blurred background.
///
/// This filter is available on iOS 15.0 and later.
@available(iOS 15.0, *)
public final class BlurBackgroundVideoFilter: VideoFilter, @unchecked Sendable {
    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) { fatalError() }

    /// Creates a filter that applies a Gaussian blur to the background.
    /// - Parameters:
    ///   - blurRadius: Radius used by the Gaussian blur.
    ///   - downscaleFactor: Downscales before blur to improve performance.
    public init(
        blurRadius: CGFloat = 20,
        downscaleFactor: CGFloat = 0.5
    ) {
        let clampedDownscale = max(min(downscaleFactor, 1), 0.1)
        let radius = blurRadius
        let backgroundImageFilterProcessor = BackgroundImageFilterProcessor()
        let name = String(describing: type(of: self)).lowercased()

        super.init(
            id: "io.getstream.\(name)",
            name: name,
            filter: { [backgroundImageFilterProcessor] input in
                let srcImage = input.originalImage
                let extent = srcImage.extent
                let workingImage: CIImage
                if clampedDownscale < 1 {
                    let scaleTransform = CGAffineTransform(scaleX: clampedDownscale, y: clampedDownscale)
                    workingImage = srcImage.transformed(by: scaleTransform)
                } else {
                    workingImage = srcImage
                }
                let clampedImage = workingImage.clampedToExtent()
                var blurredImage = clampedImage.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
                if clampedDownscale < 1 {
                    let scaleUpTransform = CGAffineTransform(scaleX: 1 / clampedDownscale, y: 1 / clampedDownscale)
                    blurredImage = blurredImage.transformed(by: scaleUpTransform)
                }
                let backgroundImage = blurredImage.cropped(to: extent)
                return backgroundImageFilterProcessor
                    .applyFilter(
                        input.originalPixelBuffer,
                        backgroundImage: backgroundImage
                    ) ?? input.originalImage
            }
        )
    }
}
