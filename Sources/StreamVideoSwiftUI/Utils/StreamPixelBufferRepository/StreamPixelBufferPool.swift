//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation
import StreamVideo

/// A class managing a pool of pixel buffers to optimize memory usage during video processing.
///
/// A CVPixelBufferPool is instrumental in optimizing video processing and real-time image manipulation by
/// enhancing memory efficiency and performance. It achieves this by reusing pixel buffers, which curtails
/// the frequent allocation and deallocation of memory, a common bottleneck in real-time processing.
///
/// This reuse not only boosts performance but also aids in effective resource management, maintaining a
/// controlled memory footprint and preventing memory pressure. The pool ensures that all buffers share
/// consistent attributes like size and format, crucial for operations expecting uniform input.
///
/// Additionally, it reduces memory fragmentation, contributing to overall system stability and efficiency.
/// Essentially, CVPixelBufferPool streamlines handling high volumes of image or video frames, ensuring
/// optimized, consistent, and fast processing.
final class StreamPixelBufferPool {

    /// Errors that can be encountered while managing the pixel buffer pool.
    enum Error: LocalizedError {

        /// Error indicating the pixel buffer pool cannot allocate more buffers without exceeding its limit.
        case returnWouldExceedAllocationThreshold

        /// Error indicating an unknown issue occurred, including the size of the buffer attempted.
        case unknown(CGSize)

        /// Error indicating that the bufferPool failed to initialise.
        case unavailableBufferPool

        /// A human-readable description of the error.
        var errorDescription: String? {
            switch self {
            case .returnWouldExceedAllocationThreshold:
                return "BufferPool is out of buffers, dropping frame"
            case let .unknown(bufferSize):
                return "An unknown error occurred while trying to dequeue a pixelBuffer for size: \(bufferSize)"
            case .unavailableBufferPool:
                return "BufferPool is unavailable."
            }
        }
    }

    /// The maximum number of pixel buffers that the pool can allocate.
    let maxNoOfBuffers: Int

    /// The size of each pixel buffer in the pool.
    let bufferSize: CGSize

    /// The pixel format type of each pixel buffer in the pool.
    let pixelFormat: OSType

    /// The underlying CVPixelBufferPool managed by this class.
    private var pool: CVPixelBufferPool?

    /// Initializes a new pixel buffer pool with specified characteristics.
    ///
    /// - Parameters:
    ///   - bufferSize: The size for each buffer in the pool.
    ///   - pixelFormat: The pixel format type, defaults to 32-bit BGRA.
    ///   - maxNoOfBuffers: The maximum number of buffers the pool can allocate, defaults to 5.
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

    /// Dequeues a pixel buffer from the pool or throws an error if none are available.
    ///
    /// - Returns: A pixel buffer from the pool.
    /// - Throws: An `Error` if it cannot dequeue a pixel buffer.
    func dequeuePixelBuffer() throws -> CVPixelBuffer {
        guard let pool = self.pool else {
            throw Error.unavailableBufferPool
        }

        var pixelBuffer: CVPixelBuffer?
        let error = CVPixelBufferPoolCreatePixelBuffer(
            nil,
            pool,
            &pixelBuffer
        )

        if error == kCVReturnWouldExceedAllocationThreshold {
            throw Error.returnWouldExceedAllocationThreshold
        } else if let pixelBuffer {
            return pixelBuffer
        } else {
            throw Error.unknown(bufferSize)
        }
    }
}
