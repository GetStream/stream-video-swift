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

class StreamVideoCaptureHandler: NSObject, RTCVideoCapturerDelegate {
    
    let source: RTCVideoSource
    let filters: [VideoFilter]
    let context: CIContext
    let colorSpace: CGColorSpace
    var selectedFilter: VideoFilter?
    var orientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }
    var sceneOrientation: UIInterfaceOrientation = .unknown
    var currentCameraPosition: AVCaptureDevice.Position = .front
    
    init(source: RTCVideoSource, filters: [VideoFilter]) {
        self.source = source
        self.filters = filters
        context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        colorSpace = CGColorSpaceCreateDeviceRGB()
        super.init()
        DispatchQueue.main.async {
            self.sceneOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        }
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
            if orientation == .unknown {
                let updatedFrame = adjustRotation(capturer, for: buffer, frame: frame)
                self.source.capturer(capturer, didCapture: updatedFrame)
            } else {
                self.source.capturer(capturer, didCapture: frame)
            }
        }
    }
    
    private func adjustRotation(
        _ capturer: RTCVideoCapturer,
        for buffer: RTCCVPixelBuffer,
        frame: RTCVideoFrame
    ) -> RTCVideoFrame {
        var rotation = RTCVideoRotation._0
        switch sceneOrientation {
        case .portrait:
            rotation = ._90
        case .portraitUpsideDown:
            rotation = ._270
        case .landscapeRight:
            rotation = currentCameraPosition == .front ? ._180 : ._0
        case .landscapeLeft:
            rotation = currentCameraPosition == .front ? ._0 : ._180
        default:
            rotation = ._90
        }
        let updatedFrame = RTCVideoFrame(buffer: buffer, rotation: rotation, timeStampNs: frame.timeStampNs)
        return updatedFrame
    }
    
    private func filter(image: CIImage) async -> CIImage {
        guard let selectedFilter = selectedFilter else { return image }
        return await selectedFilter.filter(image)
    }
}
