//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
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

    private lazy var processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private let disposableBag = DisposableBag()
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

        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else { return }
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
        guard
            let selectedFilter,
            let buffer = frame.buffer as? RTCCVPixelBuffer
        else {
            return process(capturer: capturer, frame: frame, buffer: nil)
        }

        apply(
            filter: selectedFilter,
            with: buffer,
            from: frame,
            capturer: capturer
        )
    }

    private func apply(
        filter: VideoFilter,
        with buffer: RTCCVPixelBuffer,
        from frame: RTCVideoFrame,
        capturer: RTCVideoCapturer
    ) {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }

            let imageBuffer = buffer.pixelBuffer
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            let inputImage = CIImage(
                cvPixelBuffer: imageBuffer,
                options: [CIImageOption.colorSpace: self.colorSpace]
            )
            let outputImage = await filter.filter(
                VideoFilter.Input(
                    originalImage: inputImage,
                    originalPixelBuffer: imageBuffer,
                    originalImageOrientation: sceneOrientation.cgOrientation
                )
            )
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            context.render(
                outputImage,
                to: imageBuffer,
                bounds: outputImage.extent,
                colorSpace: self.colorSpace
            )
            process(capturer: capturer, frame: frame, buffer: buffer)
        }
    }

    private func process(
        capturer: RTCVideoCapturer,
        frame: RTCVideoFrame,
        buffer: RTCCVPixelBuffer?
    ) {
        guard handleRotation else {
            return source.capturer(capturer, didCapture: frame)
        }
        let updatedFrame = adjustRotation(for: buffer, frame: frame)
        source.capturer(capturer, didCapture: updatedFrame)
    }

    private func adjustRotation(
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
