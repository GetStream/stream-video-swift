//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation
import StreamVideo

final class StreamPixelBufferPool {
    enum Error: LocalizedError {
        case returnWouldExceedAllocationThreshold
        case unknown(CGSize)

        var errorDescription: String? {
            switch self {
            case .returnWouldExceedAllocationThreshold:
                return "Pool is out of buffers, dropping frame"
            case let .unknown(bufferSize):
                return "An unknown error occurred while trying to dequeue a pixelBuffer for size:\(bufferSize)"
            }
        }
    }

    let maxNoOfBuffers: Int
    let bufferSize: CGSize
    let pixelFormat: OSType

    private var pool: CVPixelBufferPool?
    private let lockQueue = UnfairQueue()

    init(
        bufferSize: CGSize,
        pixelFormat: OSType = kCVPixelFormatType_32BGRA,
        maxNoOfBuffers: Int = 5
    ) {
        self.bufferSize = bufferSize
        self.pixelFormat = pixelFormat
        self.maxNoOfBuffers = maxNoOfBuffers

        var cvPool: CVPixelBufferPool?
        let poolAttributes: [String: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey as String: maxNoOfBuffers
        ]
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(pixelFormat),
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
        pool = cvPool
    }

    func dequeuePixelBuffer() throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        try lockQueue.sync {
            if let pool = self.pool {
                let error = CVPixelBufferPoolCreatePixelBuffer(
                    nil,
                    pool,
                    &pixelBuffer
                )

                if error == kCVReturnWouldExceedAllocationThreshold {
                    throw Error.returnWouldExceedAllocationThreshold
                } else if pixelBuffer == nil {
                    throw Error.unknown(bufferSize)
                }
            }
        }
        return pixelBuffer!
    }
}
