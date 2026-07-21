//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// Handles camera-related interruptions and unexpected capture-session stops by
/// observing `AVCaptureSession` notifications.
///
/// Besides logging interruptions and restarting after an interruption ends,
/// this handler recovers from the case where the capture session stops without
/// an `AVCaptureSessionRuntimeError` — for example a capture-server connection
/// loss on join (`kFigCaptureSessionError_ServerConnectionDied`). In that case
/// the session reports as started while delivering no frames, no runtime error
/// is posted (so `RTCCameraVideoCapturer`'s own recovery never triggers), and
/// no interruption-ended notification arrives. The handler restarts capture
/// with a full stop/start cycle, matching what a manual camera toggle does.
final class CameraInterruptionsHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    /// Represents the current camera session state (idle or running).
    private enum State {
        /// No active camera session.
        case idle
        /// An active camera session with a disposable bag for cleanup.
        case running(session: AVCaptureSession, disposableBag: DisposableBag)
    }

    /// Tracks one intentional camera-position transition from its expected
    /// capture-session stop until the corresponding start notification.
    ///
    /// Instances provide transition identity in addition to ordering. This lets
    /// failure rollback remove the exact in-flight change without completing an
    /// older or newer change during rapid consecutive flips.
    private final class CameraPositionChange {
        /// Notification the transition is waiting to receive next.
        enum State: Equatable {
            /// The capture handler has not stopped the previous device yet.
            case awaitingStop
            /// The expected stop arrived; the replacement device has not started yet.
            case awaitingStart
        }

        /// Start action to restore if a later action handler rejects this change.
        let previousStartAction: StreamVideoCapturer.Action
        /// Current notification phase for this transition.
        var state: State = .awaitingStop

        init(previousStartAction: StreamVideoCapturer.Action) {
            self.previousStartAction = previousStartAction
        }
    }

    /// Maximum number of consecutive automatic restart attempts before giving
    /// up, to avoid a restart loop when the capture server cannot recover. The
    /// counter resets once capture successfully starts again.
    private static let maxRestartAttempts = 3

    /// Serializes lifecycle actions, failure callbacks, and notifications.
    ///
    /// All observers deliver on this queue through `receive(on:)`, while
    /// ``handle(_:)`` and ``handleFailure(for:)`` enqueue synchronous operations.
    /// Keeping every transition mutation here prevents capture actions from
    /// racing delayed `AVCaptureSession` notifications.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private var state: State = .idle
    private var lastStartAction: StreamVideoCapturer.Action?
    private var restartAttempts = 0
    private var isInterrupted = false
    private var isRestarting = false

    /// Intentional camera changes awaiting their stop/start notifications.
    ///
    /// Notification handlers consume this collection in FIFO order because
    /// `AVCaptureSession` posts lifecycle notifications in transition order.
    private var cameraPositionChanges: [CameraPositionChange] = []

    /// Change staged by the most recent position-change pipeline invocation.
    ///
    /// ``handleFailure(for:)`` matches this identity against the FIFO before
    /// rolling back. Once notifications complete and remove the transition, a
    /// retained reference cannot roll back an already completed change.
    private var currentCameraPositionChange: CameraPositionChange?

    /// Whether automatic recovery must remain suppressed for an intentional
    /// camera stop/start cycle.
    private var isChangingCameraPosition: Bool {
        !cameraPositionChanges.isEmpty
    }

    /// Dispatches actions back through the capturer pipeline. Assigned by
    /// ``StreamVideoCapturer`` so the handler can issue a full capture restart.
    var actionDispatcher: ((StreamVideoCapturer.Action) async -> Void)?

    // MARK: - StreamVideoCapturerActionHandler

    /// Handles camera capture lifecycle actions.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            self?.handleAction(action)
        }
    }

    /// Rolls back a staged camera-position change rejected by a later handler.
    ///
    /// The callback runs on ``processingQueue`` so it is ordered with any stop
    /// or start notification already emitted by the failed capture attempt.
    func handleFailure(for action: StreamVideoCapturer.Action) async {
        try? await processingQueue.addSynchronousTaskOperation { [weak self] in
            self?.handleActionFailure(action)
        }
    }

    // MARK: - Private

    /// Applies lifecycle bookkeeping on ``processingQueue`` before downstream
    /// handlers mutate the capture session.
    private func handleAction(_ action: StreamVideoCapturer.Action) {
        switch action {
        /// Handle start capture event and register for session notifications.
        case let .startCapture(_, _, _, _, videoCapturer, _, _):
            if let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer {
                didStartCapture(
                    session: cameraCapturer.captureSession,
                    startAction: action
                )
            } else {
                didStopCapture()
            }
        case let .setCameraPosition(position, videoSource, videoCapturer, videoCapturerDelegate):
            handleCameraPositionChange(
                position: position,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
        /// Handle stop capture event and cleanup.
        case .stopCapture:
            didStopCapture()
        default:
            break
        }
    }

    /// Sets up observers and state when camera capture starts.
    private func didStartCapture(
        session: AVCaptureSession,
        startAction: StreamVideoCapturer.Action
    ) {
        let disposableBag = DisposableBag()

        let interruptedNotification: Notification.Name = {
            #if compiler(>=6.0)
            return AVCaptureSession.wasInterruptedNotification
            #else
            return .AVCaptureSessionWasInterrupted
            #endif
        }()

        /// Observe AVCaptureSession interruptions, log reasons and remember that
        /// an interruption is active so an unexpected stop isn't misread.
        NotificationCenter
            .default
            .publisher(for: interruptedNotification, object: session)
            .compactMap { (notification: Notification) -> String? in
                guard
                    let userInfo = notification.userInfo,
                    let reasonRawValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? NSNumber,
                    let reason = AVCaptureSession.InterruptionReason(rawValue: reasonRawValue.intValue)
                else {
                    return nil
                }
                return reason.description
            }
            .log(.debug, subsystems: .webRTC) { "CameraCapture session was interrupted with reason: \($0)." }
            .receive(on: processingQueue)
            .sink { [weak self] _ in self?.setInterrupted(true) }
            .store(in: disposableBag)

        /// Observe end of AVCaptureSession interruptions and restart session if needed.
        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionInterruptionEnded, object: session)
            .log(.debug, subsystems: .webRTC) { _ in "CameraCapture session interruption ended." }
            .receive(on: processingQueue)
            .sink { [weak self] _ in self?.handleInterruptionEnded() }
            .store(in: disposableBag)

        /// Observe unexpected session stops and restart capture.
        NotificationCenter
            .default
            .publisher(for: AVCaptureSession.didStopRunningNotification, object: session)
            .receive(on: processingQueue)
            .sink { [weak self] _ in self?.handleDidStopRunning() }
            .store(in: disposableBag)

        /// Observe runtime errors and restart capture.
        ///
        /// `RTCCameraVideoCapturer` already restarts on runtime errors, but only
        /// via a bare `startRunning`. Routing them through our full stop/start
        /// recovery re-adds the device input, which is needed when a server
        /// connection loss invalidates the current input. The shared restart
        /// guard prevents this from racing the `didStopRunning` path.
        NotificationCenter
            .default
            .publisher(for: AVCaptureSession.runtimeErrorNotification, object: session)
            .receive(on: processingQueue)
            .sink { [weak self] notification in
                let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError
                self?.attemptRestart(
                    reason: "runtime error: \(error.map { "\($0)" } ?? "unknown")"
                )
            }
            .store(in: disposableBag)

        /// Observe successful (re)starts to clear the restart bookkeeping.
        NotificationCenter
            .default
            .publisher(for: AVCaptureSession.didStartRunningNotification, object: session)
            .receive(on: processingQueue)
            .sink { [weak self] _ in self?.handleDidStartRunning() }
            .store(in: disposableBag)

        state = .running(session: session, disposableBag: disposableBag)
        lastStartAction = startAction
        isInterrupted = false
        cameraPositionChanges.removeAll()
        currentCameraPositionChange = nil
    }

    /// Stages the recovery configuration for a requested camera position.
    ///
    /// The new start action is cached immediately so a successful transition
    /// recovers with the selected camera. The pending transition retains the
    /// previous action so ``handleFailure(for:)`` can restore it if downstream
    /// handling fails. Same-position requests refresh dependencies without
    /// expecting a capture-session stop.
    ///
    /// - Parameters:
    ///   - position: Camera position requested by the caller.
    ///   - videoSource: Source that receives frames from the selected camera.
    ///   - videoCapturer: Capturer performing the position change.
    ///   - videoCapturerDelegate: Delegate receiving captured frames.
    private func handleCameraPositionChange(
        position: AVCaptureDevice.Position,
        videoSource: RTCVideoSource,
        videoCapturer: RTCVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate
    ) {
        guard
            let previousStartAction = lastStartAction,
            case let .startCapture(
                currentPosition,
                dimensions,
                frameRate,
                _,
                _,
                _,
                audioDeviceModule
            ) = previousStartAction
        else {
            return
        }
        lastStartAction = .startCapture(
            position: position,
            dimensions: dimensions,
            frameRate: frameRate,
            videoSource: videoSource,
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            audioDeviceModule: audioDeviceModule
        )
        if currentPosition != position {
            let change = CameraPositionChange(previousStartAction: previousStartAction)
            cameraPositionChanges.append(change)
            currentCameraPositionChange = change
        } else {
            currentCameraPositionChange = nil
        }
    }

    /// Removes the exact transition staged by a failed position-change action
    /// and restores its last successful recovery configuration.
    ///
    /// If the transition already completed, its identity is no longer present
    /// and there is nothing to roll back.
    private func handleActionFailure(_ action: StreamVideoCapturer.Action) {
        guard
            case .setCameraPosition = action,
            let change = currentCameraPositionChange,
            let index = cameraPositionChanges.firstIndex(where: { $0 === change })
        else {
            return
        }
        cameraPositionChanges.remove(at: index)
        lastStartAction = change.previousStartAction
        currentCameraPositionChange = nil
    }

    /// Cleans up resources and resets state when camera capture stops.
    private func didStopCapture() {
        if case let .running(_, disposableBag) = state {
            disposableBag.removeAll()
        }
        state = .idle
        cameraPositionChanges.removeAll()
        currentCameraPositionChange = nil
    }

    private func setInterrupted(_ value: Bool) {
        isInterrupted = value
    }

    /// Restarts the session if it was interrupted and not running.
    private func handleInterruptionEnded() {
        isInterrupted = false
        guard
            case let .running(session, _) = state,
            !session.isRunning
        else {
            return
        }
        session.startRunning()
    }

    /// Clears restart bookkeeping and completes the oldest transition awaiting
    /// its start notification.
    ///
    /// FIFO completion prevents a delayed start from an earlier flip from
    /// clearing suppression for a newer flip.
    private func handleDidStartRunning() {
        restartAttempts = 0
        isRestarting = false
        if let index = cameraPositionChanges.firstIndex(where: { $0.state == .awaitingStart }) {
            cameraPositionChanges.remove(at: index)
        }
    }

    /// Consumes an expected position-change stop or starts recovery for a
    /// genuinely unexpected session stop.
    private func handleDidStopRunning() {
        guard let index = cameraPositionChanges.firstIndex(where: { $0.state == .awaitingStop }) else {
            attemptRestart(reason: "session stopped unexpectedly")
            return
        }
        cameraPositionChanges[index].state = .awaitingStart
    }

    /// Restarts capture when the session stops or errors while we still expect
    /// it running and no interruption we are tracking is active.
    ///
    /// Shared by the `didStopRunning` and `runtimeError` observers; the
    /// `isRestarting` guard ensures only one restart runs even when both fire
    /// for the same event.
    private func attemptRestart(reason: String) {
        guard
            case .running = state,
            !isInterrupted,
            !isRestarting,
            !isChangingCameraPosition
        else {
            return
        }
        guard restartAttempts < Self.maxRestartAttempts else {
            log.error(
                "CameraCapture did not recover (\(reason)) after \(Self.maxRestartAttempts) attempts.",
                subsystems: .webRTC
            )
            return
        }

        guard
            let startAction = lastStartAction,
            let actionDispatcher,
            case let .startCapture(_, _, _, _, videoCapturer, _, _) = startAction
        else {
            return
        }

        restartAttempts += 1
        isRestarting = true
        let attempt = restartAttempts

        log.warning(
            "CameraCapture needs recovery (\(reason)). Restarting capture (attempt \(attempt)).",
            subsystems: .webRTC
        )

        Task { [weak self] in
            // A full stop/start cycle re-adds the device input and clears the
            // capture handler's dedup guard, matching a manual camera toggle.
            await actionDispatcher(.stopCapture(videoCapturer: videoCapturer))
            await actionDispatcher(startAction)
            // Hop back onto the serial queue to clear the restart flag.
            self?.processingQueue.addOperation { [weak self] in self?.isRestarting = false }
        }
    }
}

#if compiler(>=6.0)
extension AVCaptureSession.InterruptionReason: @retroactive CustomStringConvertible {}
#else
extension AVCaptureSession.InterruptionReason: CustomStringConvertible {}
#endif

extension AVCaptureSession.InterruptionReason {
    /// Provides a readable description for each interruption reason.
    public var description: String {
        switch self {
        case .videoDeviceNotAvailableInBackground:
            return ".videoDeviceNotAvailableInBackground"
        case .audioDeviceInUseByAnotherClient:
            return ".audioDeviceInUseByAnotherClient"
        case .videoDeviceInUseByAnotherClient:
            return ".videoDeviceInUseByAnotherClient"
        case .videoDeviceNotAvailableWithMultipleForegroundApps:
            return ".videoDeviceNotAvailableWithMultipleForegroundApps"
        case .videoDeviceNotAvailableDueToSystemPressure:
            return ".videoDeviceNotAvailableDueToSystemPressure"
        #if compiler(>=6.2)
        case .sensitiveContentMitigationActivated:
            return ".sensitiveContentMitigationActivated"
        #endif
        @unknown default:
            return "\(self)"
        }
    }
}
