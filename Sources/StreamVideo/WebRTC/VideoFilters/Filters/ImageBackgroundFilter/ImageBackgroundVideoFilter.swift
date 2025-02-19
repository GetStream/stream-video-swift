//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreImage
import Foundation

/// A video filter that applies a custom image as the background.
///
/// This filter uses a provided `CIImage` as the background and combines it with
/// the foreground objects using a filter processor. It caches processed background images to optimize
/// performance for matching input sizes and orientations.
@available(iOS 15.0, *)
public final class ImageBackgroundVideoFilter: VideoFilter, @unchecked Sendable {

    private struct CacheValue: Hashable {
        var originalImageSize: CGSize
        var originalImageOrientation: CGImagePropertyOrientation
        var result: CIImage

        func hash(into hasher: inout Hasher) {
            hasher.combine(originalImageSize.width)
            hasher.combine(originalImageSize.height)
            hasher.combine(originalImageOrientation)
        }
    }

    private let backgroundImage: CIImage
    private let backgroundImageFilterProcessor = BackgroundImageFilterProcessor()

    private var cachedValue: CacheValue?

    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) { fatalError() }

    /// Initializes a new `ImageBackgroundVideoFilter` instance.
    ///
    /// - Parameters:
    ///   - backgroundImage: The `CIImage` to use as the background.
    ///   - id: A unique identifier for the filter.
    init(
        _ backgroundImage: CIImage,
        id: String
    ) {
        let name = String(describing: type(of: self))
        self.backgroundImage = backgroundImage

        super.init(id: id, name: name, filter: \.originalImage)

        filter = { [backgroundImageFilterProcessor, weak self] input in
            guard
                let backgroundImage = self?.backgroundImage(for: input)
            else {
                return input.originalImage
            }

            return backgroundImageFilterProcessor.applyFilter(
                input.originalPixelBuffer,
                backgroundImage: backgroundImage
            ) ?? input.originalImage
        }
    }

    /// Returns the cached or processed background image for a given input.
    private func backgroundImage(for input: Input) -> CIImage {
        if
            let cachedValue = cachedValue,
            cachedValue.originalImageSize == input.originalImage.extent.size,
            cachedValue.originalImageOrientation == input.originalImageOrientation {
            return cachedValue.result
        } else {
            var cachedBackgroundImage = backgroundImage.oriented(input.originalImageOrientation)

            if cachedBackgroundImage.extent.size != input.originalImage.extent.size {
                cachedBackgroundImage = cachedBackgroundImage
                    .resize(input.originalImage.extent.size) ?? cachedBackgroundImage
            }

            cachedValue = .init(
                originalImageSize: input.originalImage.extent.size,
                originalImageOrientation: input.originalImageOrientation,
                result: cachedBackgroundImage
            )
            return cachedBackgroundImage
        }
    }
}
