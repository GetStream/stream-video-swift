//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public final class VideoFilter: @unchecked Sendable {
    public let id: String
    public let name: String
    public var filter: (CIImage) async -> CIImage
    
    public init(id: String, name: String, filter: @escaping (CIImage) async -> CIImage) {
        self.id = id
        self.name = name
        self.filter = filter
    }
}

class VideoFiltersHandler: NSObject, RTCVideoCapturerDelegate {
    
    let source: RTCVideoSource
    let filters: [VideoFilter]
    let context: CIContext
    let colorSpace: CGColorSpace
    var selectedFilter: VideoFilter?
    
    init(source: RTCVideoSource, filters: [VideoFilter]) {
        self.source = source
        self.filters = filters
        context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        colorSpace = CGColorSpaceCreateDeviceRGB()
        super.init()
    }
    
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        guard let buffer: RTCCVPixelBuffer = frame.buffer as? RTCCVPixelBuffer else { return }
        Task {
            let imageBuffer = buffer.pixelBuffer
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            let inputImage = CIImage(cvPixelBuffer: imageBuffer, options: [CIImageOption.colorSpace: colorSpace])
            let outputImage = await filter(image: inputImage)
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            self.context.render(outputImage, to: imageBuffer, bounds: outputImage.extent, colorSpace: colorSpace)
            self.source.capturer(capturer, didCapture: frame)
        }
    }
    
    private func filter(image: CIImage) async -> CIImage {
        guard let selectedFilter = selectedFilter else { return image }
        return await selectedFilter.filter(image)
    }
}
