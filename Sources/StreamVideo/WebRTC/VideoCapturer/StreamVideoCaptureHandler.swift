//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamWebRTC

final class StreamVideoCaptureHandler: NSObject, RTCVideoCapturerDelegate {

    @Injected(\.orientationAdapter) private var orientationAdapter
    @Injected(\.performanceLogger) private var performanceLogger

    let source: RTCVideoSource
    let filters: [VideoFilter]
    let context: CIContext
    let colorSpace: CGColorSpace
    var selectedFilter: VideoFilter?
    var currentCameraPosition: AVCaptureDevice.Position = .front
    private let handleRotation: Bool

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
    }

    func capturer(
        _ capturer: RTCVideoCapturer,
        didCapture frame: RTCVideoFrame
    ) {
        Task { [weak self] in
            await self?.performanceLogger.measureExecution(name: #function) {
                guard let self else { return }

                var _buffer: RTCCVPixelBuffer?

                if
                    self.selectedFilter != nil,
                    let buffer: RTCCVPixelBuffer = frame.buffer as? RTCCVPixelBuffer {
                    _buffer = buffer
                    let imageBuffer = buffer.pixelBuffer
                    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
                    let inputImage = CIImage(
                        cvPixelBuffer: imageBuffer,
                        options: [CIImageOption.colorSpace: self.colorSpace]
                    )
                    let outputImage = await self.filter(image: inputImage)
                    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
                    self.context.render(
                        outputImage,
                        to: imageBuffer,
                        bounds: outputImage.extent,
                        colorSpace: self.colorSpace
                    )
                }

                let updatedFrame = self.handleRotation
                    ? self.adjustRotation(capturer, for: _buffer, frame: frame)
                    : frame

                self.source.capturer(capturer, didCapture: updatedFrame)
            }
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
        switch orientationAdapter.orientation {
        case let .portrait(isUpsideDown):
            rotation = isUpsideDown ? ._270 : ._90
        case let .landscape(isLeft):
            rotation = currentCameraPosition == .front
                ? (isLeft ? ._0 : ._180)
                : (isLeft ? ._180 : ._0)
        }
        #endif

        if
            rotation != frame.rotation,
            let _buffer = buffer ?? frame.buffer as? RTCCVPixelBuffer {
            return RTCVideoFrame(
                buffer: _buffer,
                rotation: rotation,
                timeStampNs: frame.timeStampNs
            )
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
}

extension StreamVideoCaptureHandler: @unchecked Sendable {}
