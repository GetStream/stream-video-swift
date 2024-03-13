//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation
import StreamVideo

final class StreamPixelBufferRepository {

    private struct Key: Hashable {
        var width: Int
        var height: Int
        var pixelFormat: OSType
        init(_ size: CGSize, pixelFormat: OSType) {
            width = Int(size.width)
            height = Int(size.height)
            self.pixelFormat = pixelFormat
        }
    }

    private var pools: [Key: StreamPixelBufferPool] = [:]
    private let queue = UnfairQueue()

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
    static var currentValue: StreamPixelBufferRepository = .init()
}

extension InjectedValues {
    var pixelBufferRepository: StreamPixelBufferRepository {
        get { Self[StreamPixelBufferRepository.self] }
        set { Self[StreamPixelBufferRepository.self] = newValue }
    }
}
