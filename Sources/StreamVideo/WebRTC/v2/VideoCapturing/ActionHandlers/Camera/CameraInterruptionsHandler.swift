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

    /// Maximum number of consecutive automatic restart attempts before giving
    /// up, to avoid a restart loop when the capture server cannot recover. The
    /// counter resets once capture successfully starts again.
    private static let maxRestartAttempts = 3

    /// Serializes notification handling. All observers deliver on this queue
    /// (via `receive(on:)`), so the restart bookkeeping below is mutated from a
    /// single place.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private var state: State = .idle
    private var lastStartAction: StreamVideoCapturer.Action?
    private var restartAttempts = 0
    private var isInterrupted = false
    private var isRestarting = false

    /// Dispatches actions back through the capturer pipeline. Assigned by
    /// ``StreamVideoCapturer`` so the handler can issue a full capture restart.
    var actionDispatcher: ((StreamVideoCapturer.Action) async -> Void)?

    // MARK: - StreamVideoCapturerActionHandler

    /// Handles camera capture lifecycle actions.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
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
        /// Handle stop capture event and cleanup.
        case .stopCapture:
            didStopCapture()
        default:
            break
        }
    }

    // MARK: - Private

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
            .sink { [weak self] _ in self?.attemptRestart(reason: "session stopped unexpectedly") }
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
    }

    /// Cleans up resources and resets state when camera capture stops.
    private func didStopCapture() {
        if case let .running(_, disposableBag) = state {
            disposableBag.removeAll()
        }
        state = .idle
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

    /// Clears restart bookkeeping once capture is running again.
    private func handleDidStartRunning() {
        restartAttempts = 0
        isRestarting = false
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
            !isRestarting
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
