//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Vision

@available(iOS 15.0, *)
public final class BlurBackgroundVideoFilter: VideoFilter {

    private let backgroundImageFilterProcessor = BackgroundImageFilterProcessor()

    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (CIImage, CVPixelBuffer) async -> CIImage
    ) {
        fatalError()
    }

    init() {
        let name = String(describing: type(of: self))
        super.init(id: "io.getstream.\(name)", name: name, filter: { image, _ in image })
        filter = { [backgroundImageFilterProcessor] originalImage, pixelBuffer in
            let backgroundImage = originalImage.applyingFilter("CIGaussianBlur")
            if let blurredImage = backgroundImageFilterProcessor.applyFilter(pixelBuffer, backgroundImage: backgroundImage) {
                return blurredImage
            } else {
                return originalImage
            }
        }
    }
}

@available(iOS 15.0, *)
public final class ImageBackgroundVideoFilter: VideoFilter {

    private let backgroundImage: CIImage
    private let backgroundImageFilterProcessor = BackgroundImageFilterProcessor()

    @available(*, unavailable)
    override public init(
        id: String,
        name: String,
        filter: @escaping (CIImage, CVPixelBuffer) async -> CIImage
    ) {
        fatalError()
    }

    init(_ backgroundImage: CIImage) {
        let name = String(describing: type(of: self))
        self.backgroundImage = backgroundImage
        super.init(id: "io.getstream.\(name)", name: name, filter: { image, _ in image })
        filter = { [backgroundImageFilterProcessor, backgroundImage] originalImage, pixelBuffer in
            if let blurredImage = backgroundImageFilterProcessor.applyFilter(pixelBuffer, backgroundImage: backgroundImage) {
                return blurredImage
            } else {
                return originalImage
            }
        }
    }
}

@available(iOS 15.0, *)
final class BackgroundImageFilterProcessor {
    private let requestHandler = VNSequenceRequestHandler()

    private let request: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .fast
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()

    func applyFilter(
        _ buffer: CVPixelBuffer,
        backgroundImage: CIImage
    ) -> CIImage? {
        do {
            try requestHandler.perform([request], on: buffer)

            if let maskPixelBuffer = request.results?.first?.pixelBuffer {
                let originalImage = CIImage(cvPixelBuffer: buffer)
                var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

                // Scale the mask image to fit the bounds of the video frame.
                let scaleX = originalImage.extent.width / maskImage.extent.width
                let scaleY = originalImage.extent.height / maskImage.extent.height
                maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

                // Create a colored background image.
//                let _backgroundImage = backgroundImage ?? originalImage.applyingFilter("CIGaussianBlur")

                // Blend the original, background, and mask images.
                let blendFilter = CIFilter.blendWithRedMask()
                blendFilter.inputImage = originalImage
                blendFilter.backgroundImage = backgroundImage
                blendFilter.maskImage = maskImage

                let result = blendFilter.outputImage
                return result
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension VideoFilter {

    @available(iOS 15.0, *)
    public static let blurredBackground: VideoFilter = BlurBackgroundVideoFilter()

    @available(iOS 15.0, *)
    public static func imageBackground(_ backgroundImage: CIImage) -> VideoFilter {
        ImageBackgroundVideoFilter(backgroundImage)
    }
}

extension CIImage: @unchecked Sendable {

    var customPixelBuffer: CVPixelBuffer? {
        if let _pixelBuffer = pixelBuffer {
            return _pixelBuffer
        } else {
            let attrs = [
                kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
            ] as CFDictionary
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                Int(extent.width),
                Int(extent.height),
                kCVPixelFormatType_32ARGB,
                attrs,
                &pixelBuffer
            )

            guard (status == kCVReturnSuccess) else {
                return nil
            }

            return pixelBuffer
        }
    }
}
