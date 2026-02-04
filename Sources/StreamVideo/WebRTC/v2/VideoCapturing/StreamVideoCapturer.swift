//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamWebRTC

/// Describes why a capture quality change is being applied.
///
/// Use this to distinguish user-driven or configuration-driven changes from
/// automatic system pressure adjustments. This is especially useful for
/// logging and to avoid feedback loops where an internal adjustment triggers
/// another adjustment unintentionally.
enum CaptureQualityUpdateReason {
    case external
    case systemPressure
}

/// Handles capture actions dispatched by ``StreamVideoCapturer``.
///
/// Action handlers are small, focused components that encapsulate a single
/// responsibility (e.g., focusing, zooming, or reacting to system pressure).
/// The capturer forwards every action to each handler in order, allowing each
/// handler to react, ignore, or throw an error.
///
/// Concurrency:
/// - ``handle(_:)`` is `async` and may be called from multiple tasks.
/// - Conformers must be `Sendable`; internal mutation should be synchronized
///   (for example, with dedicated queues or locks).
///
/// Error handling:
/// - Throw to signal a failure that should be surfaced to the capturer.
/// - Avoid throwing for expected "no-op" situations (e.g., action types you
///   do not handle).
protocol StreamVideoCapturerActionHandler: Sendable {
    /// Handles a capture action emitted by ``StreamVideoCapturer``.
    ///
    /// - Parameter action: The action to handle. Conformers should inspect the
    ///   case and respond only to the actions they support.
    func handle(_ action: StreamVideoCapturer.Action) async throws
}

final class StreamVideoCapturer: StreamVideoCapturing, @unchecked Sendable {

    // MARK: - Convenience Initialisers

    /// Creates a camera capturer for the provided video source.
    /// - Parameters:
    ///   - videoSource: The video source receiving captured frames.
    ///   - videoCaptureSession: The capture session used for camera input.
    ///   - audioDeviceModule: The audio device module for capture coordination.
    ///   - usesProcessingPipeline: Whether to process frames through pipeline nodes.
    static func cameraCapturer(
        with videoSource: RTCVideoSource,
        videoCaptureSession: AVCaptureSession = .init(),
        audioDeviceModule: AudioDeviceModule,
        usesProcessingPipeline: Bool,
        usesNewCapturingPipeline: Bool
    ) -> StreamVideoCapturer {
        // Route frames through the processing pipeline when enabled.
        let videoCapturerDelegate: RTCVideoCapturerDelegate = usesProcessingPipeline
            ? StreamVideoProcessPipeline(source: videoSource, nodes: [
                StreamVideoProcessPipeline.FilterNode()
            ])
            : StreamVideoCaptureHandler(source: videoSource)

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
        var actionHandlers: [StreamVideoCapturerActionHandler] = [
            CameraBackgroundAccessHandler(),
            CameraCaptureHandler(),
            CameraFocusHandler(),
            CameraCapturePhotoHandler(),
            CameraVideoOutputHandler(),
            CameraZoomHandler(),
            CameraInterruptionsHandler()
        ]

        let systemPressureHandler = CameraSystemPressureHandler()
        if usesNewCapturingPipeline {
            actionHandlers.append(systemPressureHandler)
            actionHandlers.append(CameraCaptureSessionConfigurationHandler())
        }

        let streamCapturer = StreamVideoCapturer(
            videoSource: videoSource,
            videoCapturer: RTCCameraVideoCapturer(
                delegate: videoCapturerDelegate,
                captureSession: videoCaptureSession
            ),
            videoCapturerDelegate: videoCapturerDelegate,
            audioDeviceModule: audioDeviceModule,
            actionHandlers: actionHandlers
        )

        if usesNewCapturingPipeline {
            systemPressureHandler.actionDispatcher = { [weak streamCapturer] action in
                guard let streamCapturer else { return }
                do {
                    try await streamCapturer.dispatch(action)
                } catch {
                    log.error(
                        "Failed to dispatch system pressure action: \(error).",
                        subsystems: .videoCapturer
                    )
                }
            }
        }

        return streamCapturer
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
            device: CaptureDeviceProtocol,
            videoSource: RTCVideoSource,
            videoCapturer: RTCVideoCapturer,
            videoCapturerDelegate: RTCVideoCapturerDelegate,
            reason: CaptureQualityUpdateReason
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

            case let .updateCaptureQuality(
                dimensions,
                device,
                videoSource,
                videoCapturer,
                videoCapturerDelegate,
                reason
            ):
                return ".updateCaptureQuality(dimensions:\(dimensions), device:\(customString(for: device)), videoSource:\(customString(for: videoSource)), videoCapturer:\(customString(for: videoCapturer)), videoCapturerDelegate:\(customString(for: videoCapturerDelegate)), reason:\(reason))"

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
        if let videoCapturerDelegate = videoCapturerDelegate as? StreamVideoCaptureHandler {
            videoCapturerDelegate.selectedFilter = videoFilter
        } else if let processingPipeline = videoCapturerDelegate as? StreamVideoProcessPipeline {
            processingPipeline.didUpdate(videoFilter)
        }
    }

    func updateCaptureQuality(
        _ dimensions: CGSize
    ) async throws {
        try await updateCaptureQuality(dimensions, reason: .external)
    }

    private func updateCaptureQuality(
        _ dimensions: CGSize,
        reason: CaptureQualityUpdateReason
    ) async throws {
        guard let device = videoCaptureSession?.activeVideoCaptureDevice else { return }
        try await enqueueOperation(
            for: .updateCaptureQuality(
                dimensions: dimensions,
                device: device,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate,
                reason: reason
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

    func dispatch(_ action: Action) async throws {
        try await enqueueOperation(for: action)
    }
}

private func customString(for object: AnyObject) -> String {
    "\(type(of: object))(\(Unmanaged.passUnretained(object).toOpaque()))"
}
