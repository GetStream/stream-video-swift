//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation

extension CVPixelBuffer {
    public static func make(
        with size: CGSize,
        pixelFormat: OSType,
        attributes: [String: Any] = [:]
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            pixelFormat,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess else {
            return nil
        }
        
        return pixelBuffer
    }
}
