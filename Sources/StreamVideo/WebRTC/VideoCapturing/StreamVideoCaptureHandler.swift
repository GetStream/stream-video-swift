//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@preconcurrency import StreamWebRTC

final class StreamVideoCaptureHandler: NSObject, RTCVideoCapturerDelegate {

    @Injected(\.orientationAdapter) private var orientationAdapter

    let source: RTCVideoCapturerDelegate
    let context: CIContext
    let colorSpace: CGColorSpace
    var selectedFilter: VideoFilter?
    var sceneOrientation: StreamDeviceOrientation = .portrait(isUpsideDown: false)
    var currentCameraPosition: AVCaptureDevice.Position = .front
    private let handleRotation: Bool

    private lazy var serialActor = SerialActor()
    private var orientationCancellable: AnyCancellable?

    init(
        source: RTCVideoCapturerDelegate,
        handleRotation: Bool = true
    ) {
        self.source = source
        self.handleRotation = handleRotation
        context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        colorSpace = CGColorSpaceCreateDeviceRGB()
        super.init()

        Task { @MainActor in
            orientationCancellable = orientationAdapter
                .$orientation
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: \Self.sceneOrientation, onWeak: self)
            sceneOrientation = orientationAdapter.orientation
        }
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

    private func adjustRotation(
        _ capturer: RTCVideoCapturer,
        for buffer: RTCCVPixelBuffer?,
        frame: RTCVideoFrame
    ) -> RTCVideoFrame {
        #if os(macOS) || targetEnvironment(macCatalyst)
        var rotation = RTCVideoRotation._0
        #else
        var rotation = RTCVideoRotation._90
        switch sceneOrientation {
        case let .portrait(isUpsideDown):
            rotation = isUpsideDown ? ._270 : ._90
        case let .landscape(isLeft):
            switch (isLeft, currentCameraPosition == .front) {
            case (true, true):
                rotation = ._0
            case (true, false):
                rotation = ._180
            case (false, true):
                rotation = ._180
            case (false, false):
                rotation = ._0
            }
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
}

extension StreamVideoCaptureHandler: @unchecked Sendable {}
