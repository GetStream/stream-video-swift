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
            return source.convertedPixelBuffer
        } else {
            return nil
        }
    }
}

import Accelerate
import CoreVideo

final class StreamRTCYUVBuffer: NSObject, RTCVideoFrameBuffer {

    private let source: RTCI420Buffer

    var width: Int32 { source.width }

    var height: Int32 { source.height }

    private lazy var yuvPixelBuffer = buildYUVPixelBuffer()

    private lazy var YpImageBuffer: vImage_Buffer = buildYpImageBuffer()
    private lazy var CbImageBuffer: vImage_Buffer = buildCbImageBuffer()
    private lazy var CrImageBuffer: vImage_Buffer = buildCrImageBuffer()

    init(source: RTCI420Buffer) {
        self.source = source
    }

    func toI420() -> any RTCI420BufferProtocol { source }

    func toYUVPixelBuffer() -> CVPixelBuffer { yuvPixelBuffer }

    // MARK: - Private Helpers

    private func buildYUVPixelBuffer() -> CVPixelBuffer {
        fatalError()
    }

    private func buildYpImageBuffer() -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataY),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: Int(source.strideY)
        )
    }

    private func buildCbImageBuffer() -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataU),
            height: vImagePixelCount(source.chromaHeight),
            width: vImagePixelCount(source.chromaWidth),
            rowBytes: Int(source.strideU)
        )
    }

    private func buildCrImageBuffer() -> vImage_Buffer {
        vImage_Buffer(
            data: UnsafeMutablePointer(mutating: source.dataV),
            height: vImagePixelCount(source.chromaHeight),
            width: vImagePixelCount(source.chromaWidth),
            rowBytes: Int(source.strideV)
        )
    }
}

extension RTCI420Buffer {

    private static var conversionMatrix: vImage_YpCbCrToARGB = {
        var pixelRange = vImage_YpCbCrPixelRange(
            Yp_bias: 0,
            CbCr_bias: 128,
            YpRangeMax: 255,
            CbCrRangeMax: 255,
            YpMax: 255,
            YpMin: 1,
            CbCrMax: 255,
            CbCrMin: 0
        )
        var matrix = vImage_YpCbCrToARGB()
        vImageConvert_YpCbCrToARGB_GenerateConversion(
            kvImage_YpCbCrToARGBMatrix_ITU_R_601_4,
            // kvImage_YpCbCrToARGBMatrix_ITU_R_709_2, // Performance improvement with kvImage_YpCbCrToARGBMatrix_ITU_R_601_4
            &pixelRange,
            &matrix,
            kvImage420Yp8_Cb8_Cr8,
            kvImageARGB8888,
            UInt32(kvImageNoFlags)
        )
        return matrix
    }()

    var convertedPixelBuffer: CVPixelBuffer? {
        measureExecutionTime { () -> CVPixelBuffer? in
            let width = Int(self.width)
            let height = Int(self.height)

            guard let pixelBuffer = CVPixelBuffer.make(
                with: .init(width: width, height: height),
                pixelFormat: kCVPixelFormatType_32BGRA,
                attributes: [
                    kCVPixelBufferMetalCompatibilityKey as String: kCFBooleanTrue as Any,
                    kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue as Any,
                    kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue as Any
                ]
            ) else {
                return nil
            }

            let lumaBaseAddress = UnsafeMutablePointer(mutating: dataY)
            let lumaWidth = width
            let lumaHeight = height
            let lumaRowBytes = Int(strideY)
            var sourceLumaBuffer = vImage_Buffer(
                data: lumaBaseAddress,
                height: vImagePixelCount(lumaHeight),
                width: vImagePixelCount(lumaWidth),
                rowBytes: lumaRowBytes
            )

            let uBaseAddress = UnsafeMutablePointer(mutating: self.dataU)
            let uRowBytes = Int(self.strideU)
            var sourceUBuffer = vImage_Buffer(
                data: uBaseAddress,
                height: vImagePixelCount(chromaHeight),
                width: vImagePixelCount(chromaWidth),
                rowBytes: uRowBytes
            )

            let vBaseAddress = UnsafeMutablePointer(mutating: self.dataV)
            let vRowBytes = Int(self.strideV)
            var sourceVBuffer = vImage_Buffer(
                data: vBaseAddress,
                height: vImagePixelCount(self.chromaHeight),
                width: vImagePixelCount(self.chromaWidth),
                rowBytes: vRowBytes
            )

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
            var output = vImage_Buffer(
                data: baseAddress,
                height: vImagePixelCount(height),
                width: vImagePixelCount(width),
                rowBytes: CVPixelBufferGetBytesPerRow(pixelBuffer)
            )

            let error = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(
                &sourceLumaBuffer,
                &sourceUBuffer,
                &sourceVBuffer,
                &output,
                &Self.conversionMatrix,
                [3, 2, 1, 0],
                255,
                vImage_Flags(kvImageNoFlags)
            )
            //            let error = vImageConvert_420Yp8_CbCr8ToARGB8888(
            //                &sourceLumaBuffer,
            //                &sourceChromaBuffer,
            //                &output,
            //                &Self.conversionMatrix,
            //                [3, 2, 1, 0],
            //                255,
            //                vImage_Flags(kvImageNoFlags)
            //            )

            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

            if error != kvImageNoError {
                debugPrint(error)
                return nil
            } else {
                return pixelBuffer
            }
        }
    }

    var interleavedData: (pointer: UnsafeMutableRawPointer, deallocate: () -> Void) {
        let chromaSize = Int(chromaWidth * chromaHeight) // For 4:2:0, U and V each have width/2 and height/2
        let uvPlane = UnsafeMutablePointer<UInt8>
            .allocate(capacity: chromaSize * 2) // *2 because we store U and V for each chroma pixel

        let uPlane = dataU
        let vPlane = dataV

        for i in 0..<chromaSize {
            uvPlane[2 * i] = uPlane[i] // U value
            uvPlane[2 * i + 1] = vPlane[i] // V value
        }

        return (pointer: UnsafeMutableRawPointer(uvPlane), deallocate: { uvPlane.deallocate() })
    }

    var chromaSize: CGSize {
        .init(width: Int(chromaWidth), height: Int(chromaHeight))
    }

    var isInterleaved: Bool { strideU == strideV }

    var chromaStride: Int { Int(strideU) }
}

func measureExecutionTime<V>(
    of closure: () -> V,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
) -> V {
    let startTime = DispatchTime.now()
    let result = closure()
    let endTime = DispatchTime.now()

    let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let milliseconds = Double(nanoseconds) / 1_000_000

    log.debug(
        "Execution time: \(milliseconds) ms",
        functionName: function,
        fileName: file,
        lineNumber: line
    )
    return result
}

final class StreamPixelBufferPool {
    let maxNoOfBuffers: Int
    let bufferSize: CGSize
    let pixelFormat: OSType

    private var pool: CVPixelBufferPool?
    private let lockQueue = UnfairQueue()

    init(
        bufferSize: CGSize,
        pixelFormat: OSType = kCVPixelFormatType_32BGRA,
        maxNoOfBuffers: Int = 5
    ) {
        self.bufferSize = bufferSize
        self.pixelFormat = pixelFormat
        self.maxNoOfBuffers = maxNoOfBuffers

        var cvPool: CVPixelBufferPool?
        let poolAttributes: [String: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey as String: maxNoOfBuffers
        ]
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(pixelFormat),
            kCVPixelBufferWidthKey as String: Int(bufferSize.width),
            kCVPixelBufferHeightKey as String: Int(bufferSize.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        CVPixelBufferPoolCreate(
            nil,
            poolAttributes as CFDictionary,
            pixelBufferAttributes as CFDictionary,
            &cvPool
        )
        pool = cvPool
    }

    func dequeuePixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        lockQueue.sync {
            if let pool = self.pool {
                CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            }
        }
        return pixelBuffer
    }
}

final class StreamPixelBufferRepository {

    private struct Key: Hashable {
        var width: Int
        var height: Int
        init(_ size: CGSize) {
            width = Int(size.width)
            height = Int(size.height)
        }
    }

    private var pools: [Key: StreamPixelBufferPool] = [:]
    private let queue = UnfairQueue()

    func dequeuePixelBuffer(of size: CGSize) -> CVPixelBuffer? {
        let key = Key(size)
        return queue.sync {
            if let targetPool = pools[key] {
                return targetPool.dequeuePixelBuffer()
            } else {
                let targetPool = StreamPixelBufferPool(bufferSize: size)
                pools[key] = targetPool
                return targetPool.dequeuePixelBuffer()
            }
        }
    }
}

final class UnfairQueue {

    private let lock: os_unfair_lock_t

    init() {
        lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit { lock.deallocate() }

    func sync<T>(_ block: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try block()
    }
}
