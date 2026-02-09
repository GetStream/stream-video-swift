//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension StreamVideoProcessPipeline {

    /// Applies the active video filter to captured frames.
    final class FilterNode: StreamVideoProcessNode, @unchecked Sendable {

        private let context: CIContext = .init(
            options: [CIContextOption.useSoftwareRenderer: false]
        )
        private let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Block the capture callback until the async filter work completes.
        private let semaphore = DispatchSemaphore(value: 0)
        @Atomic private var videoFilter: VideoFilter?

        // MARK: - StreamVideoProcessNode

        /// Updates the filter used for subsequent frames.
        /// - Parameter videoFilter: The filter to apply, or `nil` to bypass filtering.
        func didUpdate(_ videoFilter: VideoFilter?) {
            self.videoFilter = videoFilter
        }

        /// Applies the current filter to the provided frame when available.
        /// - Parameter frame: The frame to process.
        /// - Returns: The processed frame.
        func didCapture(_ frame: RTCVideoFrame) -> RTCVideoFrame {
            guard
                let videoFilter,
                let frameBuffer = frame.buffer as? RTCCVPixelBuffer
            else {
                return frame
            }

            let orientation = frame.rotation.cgOrientation

            Task { [weak self, semaphore] in
                defer { semaphore.signal() }

                guard let self else {
                    return
                }

                await applyFilter(
                    videoFilter: videoFilter,
                    frameBuffer: frameBuffer,
                    orientation: orientation
                )
            }

            semaphore.wait()

            return frame
        }

        // MARK: - Private Helpers

        /// Applies the filter in-place to the frame's pixel buffer.
        /// - Parameters:
        ///   - videoFilter: The filter to apply.
        ///   - frameBuffer: The frame buffer backing the video frame.
        ///   - orientation: The frame orientation used by the filter.
        private func applyFilter(
            videoFilter: VideoFilter,
            frameBuffer: RTCCVPixelBuffer,
            orientation: CGImagePropertyOrientation
        ) async {
            let imageBuffer = frameBuffer.pixelBuffer

            CVPixelBufferLockBaseAddress(imageBuffer, [])

            let inputImage = CIImage(
                cvPixelBuffer: imageBuffer,
                options: [CIImageOption.colorSpace: self.colorSpace]
            )

            let outputImage = await videoFilter.filter(
                VideoFilter.Input(
                    originalImage: inputImage,
                    originalPixelBuffer: imageBuffer,
                    originalImageOrientation: orientation
                )
            )

            CVPixelBufferUnlockBaseAddress(imageBuffer, [])

            context.render(
                outputImage,
                to: imageBuffer,
                bounds: outputImage.extent,
                colorSpace: self.colorSpace
            )
        }
    }
}
