//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation

extension CVPixelBuffer {
    public static func make(
        with size: CGSize,
        pixelFormat: OSType
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?

        let attributes: [CFString: Any] = [:]

        _ = CVPixelBufferCreate(
            nil,
            Int(size.width),
            Int(size.height),
            pixelFormat,
            attributes as CFDictionary,
            &pixelBuffer
        )

        return pixelBuffer
    }
}
