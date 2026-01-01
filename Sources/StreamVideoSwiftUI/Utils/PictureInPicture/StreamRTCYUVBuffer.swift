//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Accelerate
import CoreVideo
import Foundation
import StreamVideo
import StreamWebRTC

/// A class that encapsulates the conversion of RTC video frame buffers from YUV to ARGB format.
final class StreamRTCYUVBuffer: NSObject, RTCVideoFrameBuffer {

    @Injected(\.pixelBufferRepository) private var pixelBufferRepository

    /// The original source of the video frame, conforming to `RTCVideoFrameBuffer`.
    private let source: RTCVideoFrameBuffer

    /// The conversion mechanism from YUV to ARGB.
    private let conversion: StreamYUVToARGBConversion

    /// The width of the video frame.
    var width: Int32 { source.width }

    /// The height of the video frame.
    var height: Int32 { source.height }

    /// Lazily initialized pixel buffer that stores the converted YUV to ARGB data.
    private lazy var i420ToYUVPixelBuffer = buildI420ToYUVPixelBuffer()

    /// Initializes a new buffer with the given source and conversion setup.
    ///
    /// - Parameters:
    ///   - source: The video frame source.
    ///   - conversion: The conversion configuration, default initialized if not provided.
    init(
        source: RTCVideoFrameBuffer,
        conversion: StreamYUVToARGBConversion = .init()
    ) {
        self.source = source
        self.conversion = conversion
    }

    /// Converts the frame to the I420 format.
    ///
    /// - Returns: An object conforming to `RTCI420BufferProtocol`.
    func toI420() -> any RTCI420BufferProtocol {
        if let i420 = source as? RTCI420Buffer {
            return i420
        } else {
            return source.toI420()
        }
    }

    /// Resizes the current buffer resized to the target size.
    ///
    /// - Parameter targetSize: The target size for the buffer.
    /// - Returns: A new `StreamRTCYUVBuffer` with the resized content or nil if resizing fails.
    func resize(to targetSize: CGSize) -> StreamRTCYUVBuffer? {
        if let i420 = source as? RTCI420Buffer {
            let resizedSource = i420.cropAndScale(
                with: 0,
                offsetY: 0,
                cropWidth: Int32(source.width),
                cropHeight: Int32(source.height),
                scaleWidth: Int32(targetSize.width),
                scaleHeight: Int32(targetSize.height)
            )
            return .init(source: resizedSource, conversion: conversion)
        } else if
            let pixelBuffer = source as? RTCCVPixelBuffer,
            let dequeuedPixelBuffer = try? pixelBufferRepository.dequeuePixelBuffer(
                of: targetSize,
                pixelFormat: CVPixelBufferGetPixelFormatType(pixelBuffer.pixelBuffer)
            ) {
            let count = pixelBuffer.bufferSizeForCroppingAndScaling(to: targetSize)
            let tempBuffer: UnsafeMutableRawPointer? = malloc(count)
            pixelBuffer.cropAndScale(to: dequeuedPixelBuffer, withTempBuffer: tempBuffer)
            tempBuffer?.deallocate()
            return .init(source: RTCCVPixelBuffer(pixelBuffer: dequeuedPixelBuffer))
        } else {
            return nil
        }
    }

    /// Retrieves the underlying pixel buffer if available.
    var pixelBuffer: CVPixelBuffer? {
        if source is RTCI420Buffer {
            return i420ToYUVPixelBuffer
        } else if let pixelBuffer = source as? RTCCVPixelBuffer {
            return pixelBuffer.pixelBuffer
        } else {
            return nil
        }
    }

    /// Creates a CMSampleBuffer from the current pixel buffer, if available.
    var sampleBuffer: CMSampleBuffer? {
        guard let pixelBuffer else {
            return nil
        }

        var sampleBuffer: CMSampleBuffer?

        var timingInfo = CMSampleTimingInfo()
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard let formatDescription = formatDescription else {
            log.error("Cannot create sample buffer formatDescription.", subsystems: .pictureInPicture)
            return nil
        }

        _ = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        guard let buffer = sampleBuffer else {
            log.error("Cannot create sample buffer", subsystems: .pictureInPicture)
            return nil
        }

        let attachments: CFArray! = CMSampleBufferGetSampleAttachmentsArray(
            buffer,
            createIfNecessary: true
        )
        let dictionary = unsafeBitCast(
            CFArrayGetValueAtIndex(attachments, 0),
            to: CFMutableDictionary.self
        )
        let key = Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque()
        let value = Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
        CFDictionarySetValue(dictionary, key, value)

        return buffer
    }

    // MARK: - Private Helpers

    /// Creates a pixel buffer converted from I420 to YUV format.
    ///
    /// - Returns: A `CVPixelBuffer` containing the converted data or nil if the conversion fails.
    private func buildI420ToYUVPixelBuffer() -> CVPixelBuffer? {
        guard let source = source as? RTCI420Buffer else {
            return nil
        }

        do {
            let pixelBuffer = try pixelBufferRepository.dequeuePixelBuffer(
                of: .init(width: Int(width), height: Int(height))
            )

            var YpImageBuffer = buildYpImageBuffer(source)
            var CbImageBuffer = buildCbImageBuffer(source)
            var CrImageBuffer = buildCrImageBuffer(source)

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            var output = buildImageBuffer(from: pixelBuffer)
            /// The `vImageConvert_420Yp8_Cb8_Cr8ToARGB8888` will convert our buffer
            /// to ARGB pixel format. However, for rendering we require BGRA pixel format. The
            /// permuteMaps adds an instruction to move around the generated ARGB buffers to the
            /// positions described by the array:
            /// Example:
            /// The resulted array will be: [0: Alpha, 1: Red, 2: Green, 3: Blue]. The array that we want
            /// to get though will have the format [0: Blue, 1: Green, 2: Red, 3: Alpha].
            let error = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(
                &YpImageBuffer,
                &CbImageBuffer,
                &CrImageBuffer,
                &output,
                &conversion.output,
                [3, 2, 1, 0],
                255,
                vImage_Flags(kvImageNoFlags)
            )

            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

            if error == kvImageNoError {
                return pixelBuffer
            } else {
                log.error(error, subsystems: .pictureInPicture)
                return nil
            }
        } catch {
            log.error(error, subsystems: .pictureInPicture)
            return nil
        }
    }

    /// Constructs a `vImage_Buffer` for the Y plane from the source I420 buffer.
    ///
    /// - Parameter source: The source I420 buffer.
    /// - Returns: A `vImage_Buffer` representing the Y plane.
    private func buildYpImageBuffer(_ source: RTCI420Buffer) -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataY),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: Int(source.strideY)
        )
    }

    /// Constructs a `vImage_Buffer` for the Cb plane from the source I420 buffer.
    ///
    /// - Parameter source: The source I420 buffer.
    /// - Returns: A `vImage_Buffer` representing the Cb plane.
    private func buildCbImageBuffer(_ source: RTCI420Buffer) -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataU),
            height: vImagePixelCount(source.chromaHeight),
            width: vImagePixelCount(source.chromaWidth),
            rowBytes: Int(source.strideU)
        )
    }

    /// Constructs a `vImage_Buffer` for the Cr plane from the source I420 buffer.
    ///
    /// - Parameter source: The source I420 buffer.
    /// - Returns: A `vImage_Buffer` representing the Cr plane.
    private func buildCrImageBuffer(_ source: RTCI420Buffer) -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataV),
            height: vImagePixelCount(source.chromaHeight),
            width: vImagePixelCount(source.chromaWidth),
            rowBytes: Int(source.strideV)
        )
    }

    /// Creates a `vImage_Buffer` from a CVPixelBuffer.
    ///
    /// - Parameter pixelBuffer: The pixel buffer to convert.
    /// - Returns: A `vImage_Buffer` representing the given pixel buffer.
    private func buildImageBuffer(from pixelBuffer: CVPixelBuffer) -> vImage_Buffer {
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
        return vImage_Buffer(
            data: baseAddress,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: CVPixelBufferGetBytesPerRow(pixelBuffer)
        )
    }
}
