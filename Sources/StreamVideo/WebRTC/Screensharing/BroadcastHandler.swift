import Foundation
import CoreMedia
import ImageIO

public func serializePixelBuffer(buffer: CVPixelBuffer) -> Data? {
    let pixelFormat = CVPixelBufferGetPixelFormatType(buffer)
    switch pixelFormat {
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        let status = CVPixelBufferLockBaseAddress(buffer, .readOnly)
        if status != kCVReturnSuccess {
            return nil
        }
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)

        guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else {
            return nil
        }
        let yStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        let yPlaneSize = yStride * height

        guard let uvPlane = CVPixelBufferGetBaseAddressOfPlane(buffer, 1) else {
            return nil
        }
        let uvStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 1)
        let uvPlaneSize = uvStride * (height / 2)

        let headerSize: Int = 4 + 4 + 4 + 4 + 4

        let dataSize = headerSize + yPlaneSize + uvPlaneSize
        let resultBytes = malloc(dataSize)!

        var pixelFormatValue = pixelFormat
        memcpy(resultBytes.advanced(by: 0), &pixelFormatValue, 4)
        var widthValue = Int32(width)
        memcpy(resultBytes.advanced(by: 4), &widthValue, 4)
        var heightValue = Int32(height)
        memcpy(resultBytes.advanced(by: 4 + 4), &heightValue, 4)
        var yStrideValue = Int32(yStride)
        memcpy(resultBytes.advanced(by: 4 + 4 + 4), &yStrideValue, 4)
        var uvStrideValue = Int32(uvStride)
        memcpy(resultBytes.advanced(by: 4 + 4 + 4 + 4), &uvStrideValue, 4)

        memcpy(resultBytes.advanced(by: headerSize), yPlane, yPlaneSize)
        memcpy(resultBytes.advanced(by: headerSize + yPlaneSize), uvPlane, uvPlaneSize)

        return Data(bytesNoCopy: resultBytes, count: dataSize, deallocator: .free)
    default:
        return nil
    }
}

public func deserializePixelBuffer(data: Data) -> CVPixelBuffer? {
    if data.count < 4 + 4 + 4 + 4 {
        return nil
    }
    let count = data.count
    return data.withUnsafeBytes { bytes -> CVPixelBuffer? in
        let dataBytes = bytes.baseAddress!

        var pixelFormat: UInt32 = 0
        memcpy(&pixelFormat, dataBytes.advanced(by: 0), 4)

        switch pixelFormat {
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            break
        default:
            return nil
        }

        var width: Int32 = 0
        memcpy(&width, dataBytes.advanced(by: 4), 4)
        var height: Int32 = 0
        memcpy(&height, dataBytes.advanced(by: 4 + 4), 4)
        var yStride: Int32 = 0
        memcpy(&yStride, dataBytes.advanced(by: 4 + 4 + 4), 4)
        var uvStride: Int32 = 0
        memcpy(&uvStride, dataBytes.advanced(by: 4 + 4 + 4 + 4), 4)

        if width < 0 || width > 8192 {
            return nil
        }
        if height < 0 || height > 8192 {
            return nil
        }

        let headerSize: Int = 4 + 4 + 4 + 4 + 4

        let yPlaneSize = Int(yStride * height)
        let uvPlaneSize = Int(uvStride * height / 2)
        let dataSize = headerSize + yPlaneSize + uvPlaneSize

        if dataSize > count {
            return nil
        }

        var buffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(nil, Int(width), Int(height), pixelFormat, nil, &buffer)
        if let buffer = buffer {
            let status = CVPixelBufferLockBaseAddress(buffer, [])
            if status != kCVReturnSuccess {
                return nil
            }
            defer {
                CVPixelBufferUnlockBaseAddress(buffer, [])
            }

            guard let destYPlane = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else {
                return nil
            }
            let destYStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
            if destYStride != Int(yStride) {
                return nil
            }

            guard let destUvPlane = CVPixelBufferGetBaseAddressOfPlane(buffer, 1) else {
                return nil
            }
            let destUvStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 1)
            if destUvStride != Int(uvStride) {
                return nil
            }

            memcpy(destYPlane, dataBytes.advanced(by: headerSize), yPlaneSize)
            memcpy(destUvPlane, dataBytes.advanced(by: headerSize + yPlaneSize), uvPlaneSize)

            return buffer
        } else {
            return nil
        }
    }
}
