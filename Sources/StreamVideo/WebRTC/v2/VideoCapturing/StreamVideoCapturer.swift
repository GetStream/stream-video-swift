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

    /// Creates a camera capturer for the provided video source.
    /// - Parameters:
    ///   - videoSource: The video source receiving captured frames.
    ///   - videoCaptureSession: The capture session used for camera input.
    ///   - audioDeviceModule: The audio device module for capture coordination.
    static func cameraCapturer(
        with videoSource: RTCVideoSource,
        videoCaptureSession: AVCaptureSession = .init(),
        audioDeviceModule: AudioDeviceModule
    ) -> StreamVideoCapturer {
        let videoCapturerDelegate = StreamVideoCaptureHandler(source: videoSource)

        #if targetEnvironment(simulator)
        let videoCapturer: RTCVideoCapturer = {
            if let videoURL = InjectedValues[\.simulatorStreamFile] {
                return SimulatorScreenCapturer(
                    delegate: videoCapturerDelegate,
                    videoURL: videoURL
                )
            } else {
                return RTCFileVideoCapturer(delegate: videoSource)
            }
        }()
        return .init(
            videoSource: videoSource,
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            audioDeviceModule: audioDeviceModule,
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
            audioDeviceModule: audioDeviceModule,
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

    /// Creates a screen sharing capturer for the provided video source.
    /// - Parameters:
    ///   - videoSource: The video source receiving captured frames.
    ///   - audioDeviceModule: The audio device module for capture coordination.
    ///   - includeAudio: Whether to capture app audio during screen sharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    static func screenShareCapturer(
        with videoSource: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule,
        includeAudio: Bool
    ) -> StreamVideoCapturer {
        .init(
            videoSource: videoSource,
            videoCapturer: RTCVideoCapturer(delegate: videoSource),
            videoCapturerDelegate: videoSource,
            audioDeviceModule: audioDeviceModule,
            actionHandlers: [
                ScreenShareCaptureHandler(includeAudio: includeAudio)
            ]
        )
    }

    /// Creates a broadcast capturer for the provided video source.
    /// - Parameters:
    ///   - videoSource: The video source receiving captured frames.
    ///   - audioDeviceModule: The audio device module for capture coordination.
    static func broadcastCapturer(
        with videoSource: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule
    ) -> StreamVideoCapturer {
        .init(
            videoSource: videoSource,
            videoCapturer: RTCVideoCapturer(delegate: videoSource),
            videoCapturerDelegate: videoSource,
            audioDeviceModule: audioDeviceModule,
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
            videoCapturerDelegate: RTCVideoCapturerDelegate,
            audioDeviceModule: AudioDeviceModule
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

        var description: String {
            switch self {
            case let .checkBackgroundCameraAccess(videoCaptureSession):
                return ".checkBackgroundCameraAccess(videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .startCapture(
                position,
                dimensions,
                frameRate,
                videoSource,
                videoCapturer,
                videoCapturerDelegate,
                audioDeviceModule
            ):
                var result = ".startCapture {"
                result += " position:\(position)"
                result += ", dimensions:\(dimensions)"
                result += ", frameRate:\(frameRate)"
                result += ", videoSource:\(customString(for: videoSource))"
                result += ", videoCapturer:\(customString(for: videoCapturer))"
                result += ", videoCapturerDelegate:\(customString(for: videoCapturerDelegate))"
                result += ", audioDeviceModule:\(audioDeviceModule))"
                result += " }"
                return result

            case let .stopCapture(videoCapturer):
                return ".stopCapture(videoCapturer:\(customString(for: videoCapturer)))"

            case let .setCameraPosition(position, videoSource, videoCapturer, videoCapturerDelegate):
                return ".startCapture(position:\(position), videoSource:\(customString(for: videoSource)), videoCapturer:\(customString(for: videoCapturer)), videoCapturerDelegate:\(customString(for: videoCapturerDelegate)))"

            case let .updateCaptureQuality(dimensions, device, videoSource, videoCapturer, videoCapturerDelegate):
                return ".startCapture(dimensions:\(dimensions), device:\(customString(for: device)), videoSource:\(customString(for: videoSource)), videoCapturer:\(customString(for: videoCapturer)), videoCapturerDelegate:\(customString(for: videoCapturerDelegate)))"

            case let .focus(point, videoCaptureSession):
                return ".focus(point:\(point), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .addCapturePhotoOutput(capturePhotoOutput, videoCaptureSession):
                return ".addCapturePhotoOutput(capturePhotoOutput:\(capturePhotoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .removeCapturePhotoOutput(capturePhotoOutput, videoCaptureSession):
                return ".removeCapturePhotoOutput(capturePhotoOutput:\(capturePhotoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .addVideoOutput(videoOutput, videoCaptureSession):
                return ".addVideoOutput(videoOutput:\(videoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .removeVideoOutput(videoOutput, videoCaptureSession):
                return ".removeVideoOutput(videoOutput:\(videoOutput), videoCaptureSession:\(customString(for: videoCaptureSession)))"

            case let .zoom(factor, videoCaptureSession):
                return ".zoom(factor:\(factor), videoCaptureSession:\(customString(for: videoCaptureSession)))"
            }
        }
    }

    // MARK: - Properties

    private let videoSource: RTCVideoSource
    private let videoCapturer: RTCVideoCapturer
    private let videoCapturerDelegate: RTCVideoCapturerDelegate
    private let audioDeviceModule: AudioDeviceModule
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
        audioDeviceModule: AudioDeviceModule,
        actionHandlers: [StreamVideoCapturerActionHandler]
    ) {
        self.videoSource = videoSource
        self.videoCapturer = videoCapturer
        self.videoCapturerDelegate = videoCapturerDelegate
        self.audioDeviceModule = audioDeviceModule
        self.actionHandlers = actionHandlers
    }

    // MARK: - Accessors

    func actionHandler<T: StreamVideoCapturerActionHandler>() -> T? {
        actionHandlers.first { $0 is T } as? T
    }

    func supportsBackgrounding() -> Bool {
        if #available(iOS 16.0, *) {
            return videoCaptureSession?.isMultitaskingCameraAccessSupported ?? false
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
                videoCapturerDelegate: videoCapturerDelegate,
                audioDeviceModule: audioDeviceModule
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

    // MARK: - Private

    private func enqueueOperation(
        for action: Action
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else {
                return
            }
            let actionHandlers = self.actionHandlers
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
