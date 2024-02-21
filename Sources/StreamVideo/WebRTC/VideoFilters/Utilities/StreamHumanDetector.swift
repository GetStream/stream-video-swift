//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import Vision

@available(iOS 15.0, *)
final class StreamHumanDetector {

    private let processingQueue: DispatchQueue

    init(processingQueue: DispatchQueue = .global(qos: .userInteractive)) {
        self.processingQueue = processingQueue
    }

    func detectHuman(
        in pixelBuffer: CVPixelBuffer
    ) async throws -> CVPixelBuffer? {
        try await withCheckedThrowingContinuation { _ in
            let requestHandler = VNImageRequestHandler(
                ciImage: .init(cvPixelBuffer: pixelBuffer)
            )
            processingQueue.async {}
        }
    }
}

extension VNImageRequestHandler: @unchecked Sendable {}
extension VNDetectHumanRectanglesRequest: @unchecked Sendable {}
