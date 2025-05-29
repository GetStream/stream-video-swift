//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    private lazy var processingQueue = SerialActorQueue()
    private let disposableBag = DisposableBag()
    private var orientationCancellable: AnyCancellable?

    init(
        source: RTCVideoCapturerDelegate,
        handleRotation: Bool = false
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
        processingQueue.async { [weak self] in
            guard let self else { return }
            let imageBuffer = buffer.pixelBuffer
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            let inputImage = CIImage(
                cvPixelBuffer: imageBuffer,
                options: [CIImageOption.colorSpace: colorSpace]
            )
            let outputImage = await filter.filter(
                VideoFilter.Input(
                    originalImage: inputImage,
                    originalPixelBuffer: imageBuffer,
                    originalImageOrientation: orientationAdapter.orientation.cgOrientation
                )
            )
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            context.render(
                outputImage,
                to: imageBuffer,
                bounds: outputImage.extent,
                colorSpace: colorSpace
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

        guard
            rotation != frame.rotation,
            let buffer = buffer ?? (frame.buffer as? RTCCVPixelBuffer)
        else {
            return frame
        }
        return .init(
            buffer: buffer,
            rotation: rotation,
            timeStampNs: frame.timeStampNs
        )
    }
}

extension StreamVideoCaptureHandler: @unchecked Sendable {}
