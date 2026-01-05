//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation
import StreamVideo

extension CVPixelBuffer {
    static func make(bufferSize: CGSize = .init(width: 100, height: 100)) throws -> CVPixelBuffer {
        var cvPool: CVPixelBufferPool?
        let poolAttributes: [String: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey as String: 5
        ]
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: Int(bufferSize.width),
            kCVPixelBufferHeightKey as String: Int(bufferSize.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        CVPixelBufferPoolCreate(
            nil,
            poolAttributes as CFDictionary,
            pixelBufferAttributes as CFDictionary,
            &cvPool
        )
        guard let pool = cvPool else {
            throw ClientError()
        }

        var pixelBuffer: CVPixelBuffer?
        let error = CVPixelBufferPoolCreatePixelBuffer(
            nil,
            pool,
            &pixelBuffer
        )

        if error == kCVReturnWouldExceedAllocationThreshold {
            throw ClientError("\(kCVReturnWouldExceedAllocationThreshold)")
        } else if let pixelBuffer {
            return pixelBuffer
        } else {
            throw ClientError()
        }
    }
}
