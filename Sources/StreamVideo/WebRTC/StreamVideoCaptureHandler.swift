//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamWebRTC

final class StreamVideoCaptureHandler: NSObject, RTCVideoCapturerDelegate {

    let source: RTCVideoSource
    let filters: [VideoFilter]
    let context: CIContext
    let colorSpace: CGColorSpace
    var selectedFilter: VideoFilter?
    var sceneOrientation: UIInterfaceOrientation = .unknown
    var currentCameraPosition: AVCaptureDevice.Position = .front
    private let handleRotation: Bool
    private var notification: NSNotification.Name?

    private lazy var serialActor = SerialActor()

    init(
        source: RTCVideoSource,
        filters: [VideoFilter],
        handleRotation: Bool = true
    ) {
        self.source = source
        self.filters = filters
        self.handleRotation = handleRotation
        context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        colorSpace = CGColorSpaceCreateDeviceRGB()
        super.init()
        Task { @MainActor in
            notification = UIDevice.orientationDidChangeNotification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.updateRotation),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
        }
        updateRotation()
    }

    func capturer(
        _ capturer: RTCVideoCapturer,
        didCapture frame: RTCVideoFrame
    ) {
        Task { [serialActor, weak self] in
            do {
                try await serialActor.execute { [weak self] in
                    guard let self else { return }

                    var _buffer: RTCCVPixelBuffer?

                    if self.selectedFilter != nil, let buffer: RTCCVPixelBuffer = frame.buffer as? RTCCVPixelBuffer {
                        _buffer = buffer
                        let imageBuffer = buffer.pixelBuffer
                        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
                        let inputImage = CIImage(cvPixelBuffer: imageBuffer, options: [CIImageOption.colorSpace: self.colorSpace])
                        let outputImage = await self.filter(image: inputImage, pixelBuffer: imageBuffer)
                        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
                        self.context.render(outputImage, to: imageBuffer, bounds: outputImage.extent, colorSpace: self.colorSpace)
                    }

                    let updatedFrame = self.handleRotation
                        ? self.adjustRotation(capturer, for: _buffer, frame: frame)
                        : frame

                    self.source.capturer(capturer, didCapture: updatedFrame)
                }
            } catch {
                log.error(error)
            }
        }
    }

    @objc private func updateRotation() {
        Task { @MainActor in
            self.sceneOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        }
    }

    private func adjustRotation(
        _ capturer: RTCVideoCapturer,
        for buffer: RTCCVPixelBuffer?,
        frame: RTCVideoFrame
    ) -> RTCVideoFrame {
        #if os(macOS) || targetEnvironment(simulator) || targetEnvironment(macCatalyst)
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

    private func filter(
        image: CIImage,
        pixelBuffer: CVPixelBuffer
    ) async -> CIImage {
        await selectedFilter?.filter(
            VideoFilter.Input(
                originalImage: image,
                originalPixelBuffer: pixelBuffer,
                originalImageOrientation: sceneOrientation.cgOrientation
            )
        ) ?? image
    }

    deinit {
        if let notification {
            NotificationCenter.default.removeObserver(
                self,
                name: notification,
                object: nil
            )
        }
    }
}

extension StreamVideoCaptureHandler: @unchecked Sendable {}
