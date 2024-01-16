//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import AVKit
import CoreMedia
import CoreVideo
import StreamVideo

extension CMSampleBuffer {
    
    static func from(_ pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?

        var timimgInfo  = CMSampleTimingInfo()
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        _ = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
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
}

func convertI420BufferToPixelBuffer(_ i420Buffer: RTCI420Buffer) -> CVPixelBuffer? {
    let width = Int(i420Buffer.width)
    let height = Int(i420Buffer.height)

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
    let yPlane = i420Buffer.dataY
    let uPlane = i420Buffer.dataU
    let vPlane = i420Buffer.dataV

    let yBytesPerRow = Int(i420Buffer.strideY)
    let uBytesPerRow = Int(i420Buffer.strideU)
    let vBytesPerRow = Int(i420Buffer.strideV)

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
            var pixel: [UInt8] = [0, 0, 0, 255]  // BGRA format, fully opaque

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
}


// Helper function to clamp a value to the 0-255 range
func clamp(_ value: Int) -> UInt8 {
    return UInt8(max(0, min(255, value)))
}
