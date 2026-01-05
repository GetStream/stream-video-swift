//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation
import StreamVideo

/// A repository class that manages multiple pools of pixel buffers to efficiently handle various sizes and formats.
final class StreamPixelBufferRepository {

    /// A private struct to use as a key in the dictionary that maps buffer characteristics to their respective pools.
    private struct Key: Hashable {
        /// The width of the pixel buffers in the pool.
        var width: Int
        /// The height of the pixel buffers in the pool.
        var height: Int
        /// The pixel format type of the pixel buffers in the pool.
        var pixelFormat: OSType

        /// Initializes a new key with a given size and pixel format.
        /// - Parameters:
        ///   - size: The size of the pixel buffers.
        ///   - pixelFormat: The pixel format type.
        init(_ size: CGSize, pixelFormat: OSType) {
            width = Int(size.width)
            height = Int(size.height)
            self.pixelFormat = pixelFormat
        }
    }

    /// A dictionary that maps unique keys to specific `StreamPixelBufferPool` instances.
    private var pools: [Key: StreamPixelBufferPool] = [:]

    /// A dispatch queue used for synchronizing access to the pixel buffer pools.
    private let queue = UnfairQueue()

    /// Attempts to dequeue a pixel buffer from the appropriate pool or creates a new pool if necessary.
    ///
    /// This method looks up the pool corresponding to the specified size and pixel format.
    /// If a pool doesn't exist yet, it creates a new one and then tries to dequeue a pixel buffer from it.
    ///
    /// - Parameters:
    ///   - size: The size of the pixel buffer required.
    ///   - pixelFormat: The pixel format of the buffer, defaults to 32-bit BGRA.
    /// - Returns: A pixel buffer that matches the requested size and format.
    /// - Throws: An error if a pixel buffer cannot be dequeued or created.
    func dequeuePixelBuffer(
        of size: CGSize,
        pixelFormat: OSType = kCVPixelFormatType_32BGRA
    ) throws -> CVPixelBuffer {
        let key = Key(size, pixelFormat: pixelFormat)
        return try queue.sync {
            if let targetPool = pools[key] {
                return try targetPool.dequeuePixelBuffer()
            } else {
                let targetPool = StreamPixelBufferPool(
                    bufferSize: size,
                    pixelFormat: pixelFormat
                )
                pools[key] = targetPool
                return try targetPool.dequeuePixelBuffer()
            }
        }
    }
}

extension StreamPixelBufferRepository: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamPixelBufferRepository = .init()
}

extension InjectedValues {
    var pixelBufferRepository: StreamPixelBufferRepository {
        get { Self[StreamPixelBufferRepository.self] }
        set { Self[StreamPixelBufferRepository.self] = newValue }
    }
}
