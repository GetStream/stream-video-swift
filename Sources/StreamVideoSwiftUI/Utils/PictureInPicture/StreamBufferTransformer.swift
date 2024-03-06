//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC

/// `StreamBufferTransformer` is a struct that provides methods for transforming RTCI420Buffer to
/// CVPixelBuffer, while performing downsampling when necessary.
struct StreamBufferTransformer {

    var requiresResize = false

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
    ) -> CMSampleBuffer? {
        let sourceSize = CGSize(width: Int(source.width), height: Int(source.height))

        guard
            requiresResize,
            let resizedSource = resize(source, to: resizeSize(sourceSize, toFitWithin: targetSize)),
            let pixelBuffer = convert(resizedSource.toI420())
        else {
            if let pixelBuffer = convert(source.toI420()) {
                return transform(pixelBuffer)
            } else {
                return nil
            }
        }
        return transform(pixelBuffer)
    }

    /// Transforms an CVPixelBuffer to a CMSampleBuffer.
    ///
    /// - Parameters:
    ///   - source: The source CVPixelBuffer to be transformed.
    /// - Returns: A transformed CMSampleBuffer or nil if transformation fails.
    func transform(
        _ source: CVPixelBuffer
    ) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?

        var timimgInfo = CMSampleTimingInfo()
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: source,
            formatDescriptionOut: &formatDescription
        )

        _ = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: source,
            formatDescription: formatDescription!,
            sampleTiming: &timimgInfo,
            sampleBufferOut: &sampleBuffer
        )

        guard let buffer = sampleBuffer else {
            log.error("Cannot create sample buffer")
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

    /// Resizes an RTCVideoFrameBuffer to the specified size.
    ///
    /// - Parameters:
    ///   - source: The source RTCVideoFrameBuffer to be resized.
    ///   - size: The target size for resizing.
    /// - Returns: A resized RTCVideoFrameBuffer or nil if resizing fails.
    private func resize<TargetBuffer: RTCVideoFrameBuffer>(
        _ source: TargetBuffer,
        to size: CGSize
    ) -> TargetBuffer? {
        if
            let rtcCVPixelBuffer = source as? RTCCVPixelBuffer,
            let newPixelBuffer = CVPixelBuffer.make(
                with: size,
                // Use the same pixelFormat as the source pixelBuffer to match the color profile
                pixelFormat: CVPixelBufferGetPixelFormatType(rtcCVPixelBuffer.pixelBuffer)
            ) {
            let count = rtcCVPixelBuffer.bufferSizeForCroppingAndScaling(to: size)
            let tempBuffer: UnsafeMutableRawPointer? = malloc(count)
            rtcCVPixelBuffer.cropAndScale(to: newPixelBuffer, withTempBuffer: tempBuffer)
            tempBuffer?.deallocate()
            return RTCCVPixelBuffer(pixelBuffer: newPixelBuffer) as? TargetBuffer
        } else {
            return source.cropAndScale?(
                with: 0,
                offsetY: 0,
                cropWidth: Int32(source.width),
                cropHeight: Int32(source.height),
                scaleWidth: Int32(size.width),
                scaleHeight: Int32(size.height)
            ) as? TargetBuffer
        }
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

    /// Converts an RTCVideoFrameBuffer to a CVPixelBuffer.
    ///
    /// - Parameter source: The source RTCVideoFrameBuffer to be converted.
    /// - Returns: A converted CVPixelBuffer or nil if conversion fails.
    /// - Note: It can only convert RTCCVPixelBuffer and RTCI420Buffer. Any other type will return `nil`.
    private func convert(_ source: RTCVideoFrameBuffer) -> CVPixelBuffer? {
        if let rtcCVPixelBuffer = source as? RTCCVPixelBuffer {
            return rtcCVPixelBuffer.pixelBuffer
        } else if let source = source as? RTCI420Buffer {
            let width = Int(source.width)
            let height = Int(source.height)

            // Create a BGRA pixel buffer
            var pixelBuffer: CVPixelBuffer?
            let pixelFormat = kCVPixelFormatType_32BGRA
            let pixelBufferAttrs: [String: Any] = [
                kCVPixelBufferMetalCompatibilityKey as String: kCFBooleanTrue as Any,
                kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue as Any,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue as Any
            ]

            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                pixelFormat,
                pixelBufferAttrs as CFDictionary,
                &pixelBuffer
            )

            guard status == kCVReturnSuccess, let outputPixelBuffer = pixelBuffer else {
                return nil
            }

            CVPixelBufferLockBaseAddress(outputPixelBuffer, .readOnly)

            // Get the destination BGRA plane base address
            guard let bgraBaseAddress = CVPixelBufferGetBaseAddress(outputPixelBuffer) else {
                CVPixelBufferUnlockBaseAddress(outputPixelBuffer, .readOnly)
                return nil
            }

            // Perform YUV to RGB conversion with proper chroma upsampling
            let yPlane = source.dataY
            let uPlane = source.dataU
            let vPlane = source.dataV

            let yBytesPerRow = Int(source.strideY)
            let uBytesPerRow = Int(source.strideU)
            let vBytesPerRow = Int(source.strideV)

            let bgraBytesPerRow = CVPixelBufferGetBytesPerRow(outputPixelBuffer)

            for y in stride(from: 0, to: height, by: 1) {
                for x in stride(from: 0, to: width, by: 1) {
                    let yOffset = y * yBytesPerRow + x
                    let uOffset = (y / 2) * uBytesPerRow + (x / 2)
                    let vOffset = (y / 2) * vBytesPerRow + (x / 2)

                    let yValue = Int(yPlane[yOffset])
                    let uValue = Int(uPlane[uOffset]) - 128
                    let vValue = Int(vPlane[vOffset]) - 128

                    let index = (y * bgraBytesPerRow) + (x * 4)
                    var pixel: [UInt8] = [0, 0, 0, 255] // BGRA format, fully opaque

                    // Perform YUV to RGB conversion with chroma upsampling
                    let c = yValue - 16
                    let d = uValue
                    let e = vValue

                    let r = clamp((298 * c + 409 * e + 128) >> 8)
                    let g = clamp((298 * c - 100 * d - 208 * e + 128) >> 8)
                    let b = clamp((298 * c + 516 * d + 128) >> 8)

                    pixel[0] = UInt8(b)
                    pixel[1] = UInt8(g)
                    pixel[2] = UInt8(r)

                    // Copy the pixel data to the BGRA plane
                    memcpy(bgraBaseAddress.advanced(by: index), &pixel, 4)
                }
            }

            // Unlock the BGRA pixel buffer
            CVPixelBufferUnlockBaseAddress(outputPixelBuffer, .readOnly)

            return outputPixelBuffer
        } else {
            return nil
        }
    }

    private func clamp(_ value: Int) -> UInt8 {
        UInt8(max(0, min(255, value)))
    }
}
