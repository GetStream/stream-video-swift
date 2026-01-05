//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) { fatalError() }

    /// Creates a background-replacement filter that overlays a static image.
    /// - Parameters:
    ///   - backgroundImage: Original image used as the new background.
    ///   - id: Unique identifier for the filter.
    init(
        _ backgroundImage: CIImage,
        id: String
    ) {
        let name = String(describing: type(of: self))
        let backgroundImageFilterProcessor = BackgroundImageFilterProcessor()
        let cache = Cache(backgroundImage: backgroundImage)

        super.init(
            id: id,
            name: name,
            filter: { [backgroundImageFilterProcessor, cache] input in
                let backgroundImage = cache.backgroundImage(for: input)
                return backgroundImageFilterProcessor.applyFilter(
                    input.originalPixelBuffer,
                    backgroundImage: backgroundImage
                ) ?? input.originalImage
            }
        )
    }
}

@available(iOS 15.0, *)
extension ImageBackgroundVideoFilter {

    private final class Cache: @unchecked Sendable {
        private struct Entry {
            var originalImageSize: CGSize
            var originalImageOrientation: CGImagePropertyOrientation
            var result: CIImage
        }

        private var cachedValue: Entry?
        private let backgroundImage: CIImage

        init(backgroundImage: CIImage) {
            self.backgroundImage = backgroundImage
        }

        /// Returns a cached background image sized/oriented to the input frame.
        func backgroundImage(for input: Input) -> CIImage {
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
}
