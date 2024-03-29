// The MIT License (MIT)
//
// Copyright (c) 2015-2022 Alexander Grebenyuk (github.com/kean).

import Foundation

extension ImageDecoders {
    /// A decoder that returns an empty placeholder image and attaches image
    /// data to the image container.
    struct Empty: ImageDecoding, Sendable {
        let isProgressive: Bool
        private let assetType: NukeAssetType?

        var isAsynchronous: Bool { false }

        /// Initializes the decoder.
        ///
        /// - Parameters:
        ///   - type: Image type to be associated with an image container.
        ///   `nil` by default.
        ///   - isProgressive: If `false`, returns nil for every progressive
        ///   scan. `false` by default.
        init(assetType: NukeAssetType? = nil, isProgressive: Bool = false) {
            self.assetType = assetType
            self.isProgressive = isProgressive
        }

        func decode(_ data: Data) throws -> ImageContainer {
            ImageContainer(image: PlatformImage(), type: assetType, data: data, userInfo: [:])
        }

        func decodePartiallyDownloadedData(_ data: Data) -> ImageContainer? {
            isProgressive ? ImageContainer(image: PlatformImage(), type: assetType, data: data, userInfo: [:]) : nil
        }
    }
}
