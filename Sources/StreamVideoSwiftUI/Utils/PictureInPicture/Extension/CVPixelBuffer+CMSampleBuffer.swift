//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamVideo
import SwiftUI
import UIKit

extension CVPixelBuffer {

    @MainActor
    static func build<Content: View>(
        size: CGSize,
        @ViewBuilder viewBuilder: @MainActor() async -> Content
    ) async -> CVPixelBuffer? {
        // Ensure we have valid dimensions
        let updatedSize = CGSize(
            width: max(1, size.width),
            height: max(1, size.height)
        )
        
        // Use ImageRenderer for iOS 16+ for better performance
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: await viewBuilder().frame(width: updatedSize.width, height: updatedSize.height))
            renderer.proposedSize = .init(updatedSize)
            renderer.scale = 1.0 // Use 1.0 scale to respect exact size
            
            guard let uiImage = renderer.uiImage else {
                log.error("Failed to render view to UIImage", subsystems: .pictureInPicture)
                return nil
            }
            
            return uiImage.toPixelBuffer(size: updatedSize)
        } else {
            // Fallback for older iOS versions
            let controller = UIHostingController(
                rootView: await viewBuilder()
                    .frame(width: updatedSize.width, height: updatedSize.height)
            )
            controller.view.bounds = CGRect(origin: .zero, size: updatedSize)
            controller.view.backgroundColor = .clear
            
            let renderer = UIGraphicsImageRenderer(size: updatedSize)
            let image = renderer.image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            
            return image.toPixelBuffer(size: updatedSize)
        }
    }

    /// Creates a CMSampleBuffer from the current pixel buffer, if available.
    var sampleBuffer: CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?

        var timingInfo = CMSampleTimingInfo()
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: self,
            formatDescriptionOut: &formatDescription
        )

        guard let formatDescription = formatDescription else {
            log.error("Cannot create sample buffer formatDescription.", subsystems: .pictureInPicture)
            return nil
        }

        _ = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: self,
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
}

import StreamWebRTC

extension RTCVideoFrame {
    convenience init(_ pixelBuffer: CVPixelBuffer) {
        self.init(
            buffer: RTCCVPixelBuffer(pixelBuffer: pixelBuffer),
            rotation: ._0,
            timeStampNs: 0
        )
    }
}

private extension UIImage {
    func toPixelBuffer(size: CGSize) -> CVPixelBuffer? {
        // Ensure we use exact integer dimensions
        let width = Int(ceil(size.width))
        let height = Int(ceil(size.height))
        
        var pixelBuffer: CVPixelBuffer?
        
        // Use a more video-friendly pixel format
        let pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            log.error("Failed to create pixel buffer with status: \(status)", subsystems: .pictureInPicture)
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        // Create a CIContext for efficient rendering
        let ciContext = CIContext(options: [.useSoftwareRenderer: false])
        
        guard let cgImage = self.cgImage,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            log.error("Failed to create CGImage or color space", subsystems: .pictureInPicture)
            return nil
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Render to the pixel buffer with exact size
        ciContext.render(
            ciImage,
            to: buffer,
            bounds: CGRect(x: 0, y: 0, width: width, height: height),
            colorSpace: colorSpace
        )
        
        return buffer
    }
}
