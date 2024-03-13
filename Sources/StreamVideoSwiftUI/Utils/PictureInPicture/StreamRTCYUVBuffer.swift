//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Accelerate
import CoreVideo
import Foundation
import StreamVideo
import StreamWebRTC

final class StreamRTCYUVBuffer: NSObject, RTCVideoFrameBuffer {

    @Injected(\.pixelBufferRepository) private var pixelBufferRepository

    private let source: RTCVideoFrameBuffer
    private let conversion: StreamYUVToARGBConversion

    var width: Int32 { source.width }

    var height: Int32 { source.height }

    private lazy var i420ToYUVPixelBuffer = buildI420ToYUVPixelBuffer()

    init(
        source: RTCVideoFrameBuffer,
        conversion: StreamYUVToARGBConversion = .init()
    ) {
        self.source = source
        self.conversion = conversion
    }

    func toI420() -> any RTCI420BufferProtocol {
        if let i420 = source as? RTCI420Buffer {
            return i420
        } else {
            return source.toI420()
        }
    }

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

    var pixelBuffer: CVPixelBuffer? {
        if source is RTCI420Buffer {
            return i420ToYUVPixelBuffer
        } else if let pixelBuffer = source as? RTCCVPixelBuffer {
            return pixelBuffer.pixelBuffer
        } else {
            return nil
        }
    }

    var sampleBuffer: CMSampleBuffer? {
        guard let pixelBuffer else {
            return nil
        }

        var sampleBuffer: CMSampleBuffer?

        var timimgInfo = CMSampleTimingInfo()
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

    // MARK: - Private Helpers

    private func buildI420ToYUVPixelBuffer() -> CVPixelBuffer? {
        guard let source = source as? RTCI420Buffer else {
            return nil
        }

        do {
            let pixelBuffer = try pixelBufferRepository.dequeuePixelBuffer(
                of: .init(
                    width: Int(width),
                    height: Int(
                        height
                    )
                )
            )

            var YpImageBuffer = buildYpImageBuffer(source)
            var CbImageBuffer = buildCbImageBuffer(source)
            var CrImageBuffer = buildCrImageBuffer(source)

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            var output = buildImageBuffer(from: pixelBuffer)

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
                log.error(error)
                return nil
            }
        } catch {
            log.error(error)
            return nil
        }
    }

    private func buildYpImageBuffer(_ source: RTCI420Buffer) -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataY),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: Int(source.strideY)
        )
    }

    private func buildCbImageBuffer(_ source: RTCI420Buffer) -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataU),
            height: vImagePixelCount(source.chromaHeight),
            width: vImagePixelCount(source.chromaWidth),
            rowBytes: Int(source.strideU)
        )
    }

    private func buildCrImageBuffer(_ source: RTCI420Buffer) -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataV),
            height: vImagePixelCount(source.chromaHeight),
            width: vImagePixelCount(source.chromaWidth),
            rowBytes: Int(source.strideV)
        )
    }

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
