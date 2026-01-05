//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC

/// `PictureInPictureBufferTransformer` is a struct that provides methods for transforming RTCI420Buffer to
/// CVPixelBuffer, while performing downsampling when necessary.
struct PictureInPictureBufferTransformer {

    var requiresResize = false

    /// Transforms an RTCVideoFrame's buffer  to a CMSampleBuffer with optional resizing.
    /// - Note: The current implementation always handles an i420 buffer as RTCCVPixelBuffer have been
    /// proven problematic.
    /// - Parameters:
    ///   - source: The source RTCVideoFrameBuffer to be transformed.
    ///   - targetSize: The target size for the resulting CMSampleBuffer.
    /// - Returns: A transformed RTCVideoFrame or nil if transformation fails.
    func transformAndResizeIfRequired(
        _ frame: RTCVideoFrame,
        targetSize: CGSize
    ) -> RTCVideoFrame? {
        let pixelBuffer: RTCVideoFrameBuffer? = {
            if let i420buffer = frame.buffer as? RTCI420Buffer {
                return i420buffer
            } else {
                return frame.buffer
            }
        }()

        if
            let pixelBuffer = pixelBuffer,
            let buffer = transformAndResizeIfRequired(pixelBuffer, targetSize: targetSize) {
            return .init(
                buffer: buffer,
                rotation: frame.rotation,
                timeStampNs: frame.timeStampNs
            )
        } else {
            return nil
        }
    }

    // MARK: - Private API

    /// Transforms an RTCVideoFrameBuffer to a CMSampleBuffer with optional resizing.
    /// - Note: The current implementation always handles an i420 buffer as RTCCVPixelBuffer have been
    /// proven problematic.
    /// - Parameters:
    ///   - source: The source RTCVideoFrameBuffer to be transformed.
    ///   - targetSize: The target size for the resulting CMSampleBuffer.
    /// - Returns: A transformed CMSampleBuffer or nil if transformation fails.
    func transformAndResizeIfRequired(
        _ source: RTCVideoFrameBuffer,
        targetSize: CGSize
    ) -> StreamRTCYUVBuffer? {
        let sourceSize = CGSize(width: Int(source.width), height: Int(source.height))
        let resultBuffer: StreamRTCYUVBuffer? = {
            if requiresResize {
                return .init(source: source)
                    .resize(to: resizeSize(sourceSize, toFitWithin: targetSize))
            } else {
                return .init(source: source)
            }
        }()

        return resultBuffer
    }

    /// Calculates the new size to fit within a container size while maintaining the aspect ratio.
    ///
    /// - Parameters:
    ///   - size: The original size.
    ///   - containerSize: The container size to fit within.
    /// - Returns: The new size that fits within the container while preserving the aspect ratio.
    private func resizeSize(
        _ size: CGSize,
        toFitWithin containerSize: CGSize
    ) -> CGSize {
        let widthRatio = containerSize.width / size.width
        let heightRatio = containerSize.height / size.height

        // Choose the smaller ratio to ensure that the entire original size fits
        // within the container.
        let ratioToUse = min(widthRatio, heightRatio)

        // Calculate the new size while maintaining the aspect ratio.
        let newSize = CGSize(
            width: size.width * ratioToUse,
            height: size.height * ratioToUse
        )

        return newSize
    }
}
