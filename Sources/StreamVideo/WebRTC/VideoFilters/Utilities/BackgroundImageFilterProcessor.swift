//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Vision

/// Processes a video frame to create a new image with a custom background.
///
/// This class generates a person segmentation mask using Vision, scales the mask
/// to match the video frame size, and blends the original image with a provided
/// background image using the mask. This allows for effects like background
/// replacement or blurring.
@available(iOS 15.0, *)
final class BackgroundImageFilterProcessor: @unchecked Sendable {
    private let requestHandler = VNSequenceRequestHandler()
    private let request: VNGeneratePersonSegmentationRequest

    /// Creates a processor configured with a Vision segmentation quality level.
    /// - Parameter qualityLevel: Person-mask fidelity to request from Vision.
    init(
        _ qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel = neuralEngineExists ? .balanced : .fast
    ) {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = qualityLevel
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        self.request = request
    }

    /// Applies the filter to a frame and blends it with a background image.
    /// - Parameters:
    ///   - buffer: Video frame buffer to process.
    ///   - backgroundImage: Background image used when compositing.
    /// - Returns: Processed `CIImage` or `nil` on failure.
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

                // Blend the original, background, and mask images.
                let blendFilter = CIFilter.blendWithMask()
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
