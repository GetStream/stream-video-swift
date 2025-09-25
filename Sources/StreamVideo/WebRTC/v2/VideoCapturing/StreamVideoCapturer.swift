//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamWebRTC

protocol StreamVideoCapturerActionHandler: Sendable {
    func handle(_ action: StreamVideoCapturer.Action) async throws
}

final class StreamVideoCapturer: StreamVideoCapturing {

    // MARK: - Convenience Initialisers

    static func cameraCapturer(
        with videoSource: RTCVideoSource,
        videoCaptureSession: AVCaptureSession = .init()
    ) -> StreamVideoCapturer {
        let videoCapturerDelegate = StreamVideoCaptureHandler(source: videoSource)

        #if targetEnvironment(simulator)
        let videoCapturer: RTCVideoCapturer = if let videoURL = InjectedValues[\.simulatorStreamFile] {
            SimulatorScreenCapturer(
                delegate: videoCapturerDelegate,
                videoURL: videoURL
            )
        } else {
            RTCFileVideoCapturer(delegate: videoSource)
        }
        return .init(
            videoSource: videoSource,
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            actionHandlers: [
                SimulatorCaptureHandler()
            ]
        )
        #else
        return .init(
            videoSource: videoSource,
            videoCapturer: RTCCameraVideoCapturer(
                delegate: videoCapturerDelegate,
                captureSession: videoCaptureSession
            ),
            videoCapturerDelegate: videoCapturerDelegate,
            actionHandlers: [
                CameraBackgroundAccessHandler(),
                CameraCaptureHandler(),
                CameraFocusHandler(),
                CameraCapturePhotoHandler(),
                CameraVideoOutputHandler(),
                CameraZoomHandler(),
                CameraInterruptionsHandler()
            ]
        )
        #endif
    }

    static func screenShareCapturer(
        with videoSource: RTCVideoSource
    ) -> StreamVideoCapturer {
        #if targetEnvironment(macCatalyst)
        let handler: StreamVideoCapturerActionHandler = if #available(macCatalyst 18.2, *) {
            ScreenShareCaptureHandlerMacOS()
        } else {
            ScreenShareCaptureHandler()
        }
        #else
        let handler: StreamVideoCapturerActionHandler = ScreenShareCaptureHandler()
        #endif

        return .init(
            videoSource: videoSource,
            videoCapturer: RTCVideoCapturer(delegate: videoSource),
            videoCapturerDelegate: videoSource,
            actionHandlers: [
                handler
            ]
        )
    }

    static func broadcastCapturer(
        with videoSource: RTCVideoSource
    ) -> StreamVideoCapturer {
        .init(
            videoSource: videoSource,
            videoCapturer: RTCVideoCapturer(delegate: videoSource),
            videoCapturerDelegate: videoSource,
            actionHandlers: [
                BroadcastCaptureHandler()
            ]
        )
    }

    // MARK: - Nested Types

    enum Action: @unchecked Sendable, CustomStringConvertible {
        case checkBackgroundCameraAccess(_ videoCaptureSession: AVCaptureSession)
        case startCapture(
            position: AVCaptureDevice.Position,
            dimensions: CGSize,
            frameRate: Int,
            videoSource: RTCVideoSource,
            videoCapturer: RTCVideoCapturer,
            videoCapturerDelegate: RTCVideoCapturerDelegate
        )
        case stopCapture(videoCapturer: RTCVideoCapturer)
        case setCameraPosition(
            position: AVCaptureDevice.Position,
            videoSource: RTCVideoSource,
            videoCapturer: RTCVideoCapturer,
            videoCapturerDelegate: RTCVideoCapturerDelegate
        )
        case updateCaptureQuality(
            dimensions: CGSize,
            device: AVCaptureDevice,
            videoSource: RTCVideoSource,
            videoCapturer: RTCVideoCapturer,
            videoCapturerDelegate: RTCVideoCapturerDelegate
        )
        case focus(
            point: CGPoint,
            videoCaptureSession: AVCaptureSession
        )
        case addCapturePhotoOutput(
            capturePhotoOutput: AVCapturePhotoOutput,
            videoCaptureSession: AVCaptureSession
        )
        case removeCapturePhotoOutput(
            capturePhotoOutput: AVCapturePhotoOutput,
            videoCaptureSession: AVCaptureSession
        )
        case addVideoOutput(
            videoOutput: AVCaptureVideoDataOutput,
            videoCaptureSession: AVCaptureSession
        )
        case removeVideoOutput(
            videoOutput: AVCaptureVideoDataOutput,
            videoCaptureSession: AVCaptureSession
        )
        case zoom(
            factor: CGFloat,
            videoCaptureSession: AVCaptureSession
        )

        case startAudioCapture(
            capturer: RTCPCMAudioCapturer
        )

        case stopAudioCapture

        var description: String {
            switch self {
            case let .checkBackgroundCameraAccess(videoCaptureSession):
                ".checkBackgroundCameraAccess(videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .startCapture(position, dimensions, frameRate, videoSource, videoCapturer, videoCapturerDelegate):
                ".startCapture(position:\(position), dimensions:\(dimensions), frameRate:\(frameRate), videoSource:\(customString(for: videoSource)), videoCapturer:\(customString(for: videoCapturer)), videoCapturerDelegate:\(customString(for: videoCapturerDelegate)))"

            case let .stopCapture(videoCapturer):
                ".stopCapture(videoCapturer:\(customString(for: videoCapturer)))"

            case let .setCameraPosition(position, videoSource, videoCapturer, videoCapturerDelegate):
                ".startCapture(position:\(position), videoSource:\(customString(for: videoSource)), videoCapturer:\(customString(for: videoCapturer)), videoCapturerDelegate:\(customString(for: videoCapturerDelegate)))"

            case let .updateCaptureQuality(dimensions, device, videoSource, videoCapturer, videoCapturerDelegate):
                ".startCapture(dimensions:\(dimensions), device:\(customString(for: device)), videoSource:\(customString(for: videoSource)), videoCapturer:\(customString(for: videoCapturer)), videoCapturerDelegate:\(customString(for: videoCapturerDelegate)))"

            case let .focus(point, videoCaptureSession):
                ".focus(point:\(point), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .addCapturePhotoOutput(capturePhotoOutput, videoCaptureSession):
                ".addCapturePhotoOutput(capturePhotoOutput:\(capturePhotoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .removeCapturePhotoOutput(capturePhotoOutput, videoCaptureSession):
                ".removeCapturePhotoOutput(capturePhotoOutput:\(capturePhotoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .addVideoOutput(videoOutput, videoCaptureSession):
                ".addVideoOutput(videoOutput:\(videoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .removeVideoOutput(videoOutput, videoCaptureSession):
                ".removeVideoOutput(videoOutput:\(videoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .zoom(factor, videoCaptureSession):
                ".zoom(factor:\(factor), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .startAudioCapture(capturer):
                ".startAudioCapture(capturer:\(customString(for: capturer))"

            case .stopAudioCapture:
                ".stopAudioCapture"
            }
        }
    }

    // MARK: - Properties

    private let videoSource: RTCVideoSource
    private let videoCapturer: RTCVideoCapturer
    private let videoCapturerDelegate: RTCVideoCapturerDelegate
    private let actionHandlers: [StreamVideoCapturerActionHandler]
    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    private var videoCaptureSession: AVCaptureSession? {
        guard
            let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer
        else {
            return nil
        }
        return cameraVideoCapturer.captureSession
    }

    // MARK: - Initialiser

    init(
        videoSource: RTCVideoSource,
        videoCapturer: RTCVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate,
        actionHandlers: [StreamVideoCapturerActionHandler]
    ) {
        self.videoSource = videoSource
        self.videoCapturer = videoCapturer
        self.videoCapturerDelegate = videoCapturerDelegate
        self.actionHandlers = actionHandlers
    }

    // MARK: - Accessors

    func actionHandler<T: StreamVideoCapturerActionHandler>() -> T? {
        actionHandlers.first { $0 is T } as? T
    }

    func supportsBackgrounding() -> Bool {
        if #available(iOS 16.0, *) {
            #if targetEnvironment(macCatalyst)
            return false
            #else
            return videoCaptureSession?.isMultitaskingCameraAccessSupported ?? false
            #endif
        } else {
            return false
        }
    }

    // MARK: - Actions

    func startCapture(
        position: AVCaptureDevice.Position = .front,
        dimensions: CGSize,
        frameRate: Int
    ) async throws {
        if let videoCaptureSession {
            try await enqueueOperation(
                for: .checkBackgroundCameraAccess(videoCaptureSession)
            )
        }

        try await enqueueOperation(
            for: .startCapture(
                position: position,
                dimensions: dimensions,
                frameRate: frameRate,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
        )
    }

    func stopCapture() async throws {
        try await enqueueOperation(
            for: .stopCapture(
                videoCapturer: videoCapturer
            )
        )
    }

    func setCameraPosition(_ position: AVCaptureDevice.Position) async throws {
        guard videoCaptureSession != nil else { return }
        try await enqueueOperation(
            for: .setCameraPosition(
                position: position,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
        )
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        guard
            let videoCapturerDelegate = videoCapturerDelegate as? StreamVideoCaptureHandler
        else {
            return
        }
        videoCapturerDelegate.selectedFilter = videoFilter
    }

    func updateCaptureQuality(
        _ dimensions: CGSize
    ) async throws {
        guard let device = videoCaptureSession?.activeVideoCaptureDevice else { return }
        try await enqueueOperation(
            for: .updateCaptureQuality(
                dimensions: dimensions,
                device: device,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
        )
    }

    func focus(at point: CGPoint) async throws {
        guard let videoCaptureSession else { return }
        try await enqueueOperation(
            for: .focus(
                point: point,
                videoCaptureSession: videoCaptureSession
            )
        )
    }

    func zoom(by factor: CGFloat) async throws {
        guard let videoCaptureSession else { return }
        try await enqueueOperation(
            for: .zoom(
                factor: factor,
                videoCaptureSession: videoCaptureSession
            )
        )
    }

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        guard let videoCaptureSession else { return }
        try await enqueueOperation(
            for: .addCapturePhotoOutput(
                capturePhotoOutput: capturePhotoOutput,
                videoCaptureSession: videoCaptureSession
            )
        )
    }

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        guard let videoCaptureSession else { return }
        try await enqueueOperation(
            for: .removeCapturePhotoOutput(
                capturePhotoOutput: capturePhotoOutput,
                videoCaptureSession: videoCaptureSession
            )
        )
    }

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        guard let videoCaptureSession else { return }
        try await enqueueOperation(
            for: .addVideoOutput(
                videoOutput: videoOutput,
                videoCaptureSession: videoCaptureSession
            )
        )
    }

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        guard let videoCaptureSession else { return }
        try await enqueueOperation(
            for: .removeVideoOutput(
                videoOutput: videoOutput,
                videoCaptureSession: videoCaptureSession
            )
        )
    }

    // MARK: - ScreenSharing Audio

    func startAudioCapture(
        capturer: RTCPCMAudioCapturer
    ) async throws {
        try await enqueueOperation(for: .startAudioCapture(capturer: capturer))
    }

    func stopAudioCapture() async throws {
        try await enqueueOperation(for: .stopAudioCapture)
    }

    // MARK: - Private

    private func enqueueOperation(
        for action: Action
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else {
                return
            }
            let actionHandlers = actionHandlers
            for actionHandler in actionHandlers {
                try await actionHandler.handle(action)
            }
            log.debug(
                "VideoCapturer completed execution of action:\(action).",
                subsystems: .videoCapturer
            )
        }
    }
}

private func customString(for object: AnyObject) -> String {
    "\(type(of: object))(\(Unmanaged.passUnretained(object).toOpaque()))"
}
