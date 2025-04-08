//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI
import UIKit

final class StreamPictureInPictureStaticFrameProvider: @unchecked Sendable {

    var contentSize: CGSize = .zero {
        didSet {
            if oldValue != contentSize {
                cachedFrameAccessQueue.sync { cache = nil }
            }
        }
    }

    var isActive: Bool = false {
        willSet {
            guard newValue != isActive else {
                return
            }

            if newValue, generationCancellable == nil {
                generationCancellable = Timer
                    .publish(every: interval, on: .main, in: .default)
                    .autoconnect()
                    .sinkTask { @MainActor [weak self] _ in await self?.generateFrame() }
            } else if !newValue {
                generationCancellable?.cancel()
                generationCancellable = nil
                cache = nil
            }
        }
    }

    private let interval: TimeInterval
    private let frameProcessor: StreamPictureInPictureFrameProcessor
    private let provider: (CGSize) async -> CVPixelBuffer?
    private let dataPipeline: PictureInPictureDataPipeline

    private let cachedFrameAccessQueue = UnfairQueue()
    private var cache: CVPixelBuffer?
    private var generationCancellable: AnyCancellable?
    private var lastFrameTimestamp: Int64 = 0

    init(
        fps: Int = 15,
        dataPipeline: PictureInPictureDataPipeline,
        provider: @escaping (CGSize) async -> CVPixelBuffer?
    ) {
        interval = 1 / TimeInterval(fps)
        frameProcessor = .init(dataPipeline: dataPipeline)
        self.dataPipeline = dataPipeline
        self.provider = provider
    }

    private func generateFrame() async {
        let currentTimestamp = Int64(CACurrentMediaTime() * 1_000_000_000)
        
        // Skip frame if we're generating too quickly
        guard currentTimestamp - lastFrameTimestamp >= Int64(interval * 1_000_000_000) else {
            return
        }
        
        let _frameBuffer: CVPixelBuffer? = await {
            if let cache {
                return cache
            } else {
                let result = await provider(contentSize)
                if let validBuffer = result, isValidFrame(validBuffer) {
                    cache = validBuffer
                }
                return result
            }
        }()

        guard let frameBuffer = _frameBuffer else {
            log.error("Failed to generate frame buffer", subsystems: .pictureInPicture)
            return
        }

        let frame = RTCVideoFrame(
            buffer: RTCCVPixelBuffer(pixelBuffer: frameBuffer),
            rotation: ._0,
            timeStampNs: currentTimestamp
        )

        guard let buffer = frameProcessor.process(frame)?.buffer else {
            log.error("Failed to process frame", subsystems: .pictureInPicture)
            return
        }

        lastFrameTimestamp = currentTimestamp
        dataPipeline.send(buffer)
    }
    
    private func isValidFrame(_ buffer: CVPixelBuffer) -> Bool {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        // Basic validation
        guard width > 0, height > 0 else {
            log.error("Invalid frame dimensions: \(width)x\(height)", subsystems: .pictureInPicture)
            return false
        }
        
        // Check if the buffer is locked or has invalid format
        let lockFlags = CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        guard lockFlags == kCVReturnSuccess else {
            log.error("Failed to lock pixel buffer", subsystems: .pictureInPicture)
            return false
        }
        
        return true
    }
}

#if compiler(>=6.0)
extension CVPixelBuffer: @unchecked @retroactive Sendable {}
#else
extension CVPixelBuffer: @unchecked Sendable {}
#endif
