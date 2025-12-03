//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

open class VideoFilter: @unchecked Sendable, Equatable {

    /// An object which encapsulates the required input for a Video filter.
    public struct Input {
        /// The image (video frame) that the filter should be applied on.
        public var originalImage: CIImage

        /// The pixelBuffer that produces the image (video frame) that the filter should be applied on.
        public var originalPixelBuffer: CVPixelBuffer

        /// The orientation on which the image (video frame) was generated from.
        public var originalImageOrientation: CGImagePropertyOrientation
    }

    /// The ID of the video filter.
    public let id: String

    /// The name of the video filter.
    public let name: String

    /// Filter closure that takes a CIImage as input and returns a filtered CIImage as output.
    public var filter: (Input) async -> CIImage

    /// Initializes a new VideoFilter instance with the provided parameters.
    /// - Parameters:
    ///   - id: The ID of the video filter.
    ///   - name: The name of the video filter.
    ///   - filter: The filter closure that takes a CIImage as input and returns a filtered CIImage as output.
    public init(
        id: String,
        name: String,
        filter: @escaping (Input) async -> CIImage
    ) {
        self.id = id
        self.name = name
        self.filter = filter
    }

    public static func == (lhs: VideoFilter, rhs: VideoFilter) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

extension VideoFilter {

    /// Blurs the background behind the person in the image (video frame).
    @available(iOS 15.0, *)
    public static let blurredBackground: VideoFilter = BlurBackgroundVideoFilter()

    /// Replaces the background with a provided image while keeping people.
    @available(iOS 15.0, *)
    public static func imageBackground(
        _ backgroundImage: CIImage,
        id: String
    ) -> VideoFilter {
        ImageBackgroundVideoFilter(backgroundImage, id: id)
    }

    /// Applies a blur effect over the entire frame.
    public static let blur: VideoFilter = ModerationBlurVideoFilter()
}
