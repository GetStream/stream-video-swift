//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

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
public final class BlurBackgroundVideoFilter: VideoFilter {

    private let backgroundImageFilterProcessor = BackgroundImageFilterProcessor()

    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) { fatalError() }

    init() {
        let name = String(describing: type(of: self)).lowercased()
        super.init(
            id: "io.getstream.\(name)",
            name: name,
            filter: \.originalImage
        )

        filter = { [backgroundImageFilterProcessor] input in
            let backgroundImage = input
                .originalImage
                .applyingFilter("CIGaussianBlur")

            return backgroundImageFilterProcessor
                .applyFilter(
                    input.originalPixelBuffer,
                    backgroundImage: backgroundImage
                ) ?? input.originalImage
        }
    }
}
