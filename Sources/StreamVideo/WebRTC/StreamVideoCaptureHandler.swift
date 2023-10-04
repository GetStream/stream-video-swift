//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

final class StreamVideoCaptureHandler: NSObject, RTCVideoCapturerDelegate {

    let source: RTCVideoSource
    let filters: [VideoFilter]
    let context: CIContext
    let colorSpace: CGColorSpace
    var selectedFilter: VideoFilter?
    var sceneOrientation: UIInterfaceOrientation = .unknown
    var currentCameraPosition: AVCaptureDevice.Position = .front
    private let handleRotation: Bool

    private lazy var serialActor = SerialActor()

    init(source: RTCVideoSource, filters: [VideoFilter], handleRotation: Bool = true) {
        self.source = source
        self.filters = filters
        self.handleRotation = handleRotation
        context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        colorSpace = CGColorSpaceCreateDeviceRGB()
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateRotation),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        updateRotation()
    }
    
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        Task { [serialActor] in
            await serialActor.enqueue { [weak self] in
                guard let self else { return }

                var _buffer: RTCCVPixelBuffer?

                if selectedFilter != nil, let buffer: RTCCVPixelBuffer = frame.buffer as? RTCCVPixelBuffer {
                    _buffer = buffer
                    let imageBuffer = buffer.pixelBuffer
                    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
                    let inputImage = CIImage(cvPixelBuffer: imageBuffer, options: [CIImageOption.colorSpace: colorSpace])
                    let outputImage = await filter(image: inputImage)
                    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
                    self.context.render(outputImage, to: imageBuffer, bounds: outputImage.extent, colorSpace: colorSpace)
                }

                let updatedFrame = handleRotation
                ? adjustRotation(capturer, for: _buffer, frame: frame)
                : frame

                self.source.capturer(capturer, didCapture: updatedFrame)
            }
        }
    }
    
    @objc private func updateRotation() {
        DispatchQueue.main.async {
            self.sceneOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        }
    }
    
    private func adjustRotation(
        _ capturer: RTCVideoCapturer,
        for buffer: RTCCVPixelBuffer?,
        frame: RTCVideoFrame
    ) -> RTCVideoFrame {
        #if os(macOS)
        var rotation = RTCVideoRotation._0
        #else
        var rotation = RTCVideoRotation._90
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
            break
        }
        #endif
        if rotation != frame.rotation, let _buffer = buffer ?? frame.buffer as? RTCCVPixelBuffer {
            return RTCVideoFrame(buffer: _buffer, rotation: rotation, timeStampNs: frame.timeStampNs)
        } else if rotation != frame.rotation, buffer == nil {
            log.error("Unavailable buffer for frame rotation")
            return frame
        } else {
            return frame
        }
    }
    
    private func filter(image: CIImage) async -> CIImage {
        guard let selectedFilter = selectedFilter else { return image }
        return await selectedFilter.filter(image)
    }
    
    deinit {
       NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
       )
    }
}

extension StreamVideoCaptureHandler: @unchecked Sendable {}
