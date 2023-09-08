//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

class StreamVideoCaptureHandler: NSObject, RTCVideoCapturerDelegate {
    
    let source: RTCVideoSource
    let filters: [VideoFilter]
    let context: CIContext
    let colorSpace: CGColorSpace
    var selectedFilter: VideoFilter?
    var sceneOrientation: UIInterfaceOrientation = .unknown
    var currentCameraPosition: AVCaptureDevice.Position = .front
    private let handleRotation: Bool

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
        guard let buffer: RTCCVPixelBuffer = frame.buffer as? RTCCVPixelBuffer else { return }
        Task { [weak self] in
            guard let self else { return }
            await applyFilter(on: buffer)

            let updatedFrame = handleRotation
            ? adjustRotation(capturer, for: buffer, frame: frame)
            : frame

            self.source.capturer(capturer, didCapture: updatedFrame)
        }
    }
    
    @objc private func updateRotation() {
        DispatchQueue.main.async { [weak self] in
            guard
                let self,
                let windowScene = UIApplication.shared.windows.first?.windowScene
            else { return }
            if self.sceneOrientation != windowScene.interfaceOrientation {
                log.debug("WindowScene orientation changed from \(self.sceneOrientation) → \(windowScene.interfaceOrientation)")
                self.sceneOrientation = windowScene.interfaceOrientation
            }
        }
    }
    
    private func adjustRotation(
        _ capturer: RTCVideoCapturer,
        for buffer: RTCCVPixelBuffer,
        frame: RTCVideoFrame
    ) -> RTCVideoFrame {
        var rotation = frame.rotation
        switch sceneOrientation {
        case .portrait:
            rotation = ._90
        case .portraitUpsideDown:
            rotation = ._270
        case .landscapeLeft:
            rotation = currentCameraPosition == .front ? ._0 : ._180
        case .landscapeRight:
            rotation = currentCameraPosition == .front ? ._180 : ._0
        default:
            break
        }


        return rotation != frame.rotation
        ? RTCVideoFrame(buffer: buffer, rotation: rotation, timeStampNs: frame.timeStampNs)
        : frame
    }
    
    private func applyFilter(on buffer: RTCCVPixelBuffer) async {
        if let selectedFilter {
            let imageBuffer = buffer.pixelBuffer
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            let inputImage = CIImage(cvPixelBuffer: imageBuffer, options: [CIImageOption.colorSpace: colorSpace])
            let outputImage = await selectedFilter.filter(inputImage)
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            context.render(
                outputImage,
                to: imageBuffer,
                bounds: outputImage.extent,
                colorSpace: colorSpace
            )
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
       )
    }
}
