//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// Handles camera-related interruptions by observing `AVCaptureSession` interruption notifications.
final class CameraInterruptionsHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    /// Represents the current camera session state (idle or running).
    private enum State {
        /// No active camera session.
        case idle
        /// An active camera session with a disposable bag for cleanup.
        case running(session: AVCaptureSession, disposableBag: DisposableBag)
    }

    private var state: State = .idle
    /// Ensures serialized handling of interruption events.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    // MARK: - StreamVideoCapturerActionHandler

    /// Handles camera-related actions triggered by the video capturer.
    /// Handles camera interruption actions.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        /// Handle start capture event and register for interruption notifications.
        case let .startCapture(_, _, _, _, videoCapturer, _, _):
            if let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer {
                didStartCapture(session: cameraCapturer.captureSession)
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
    private func didStartCapture(session: AVCaptureSession) {
        let disposableBag = DisposableBag()

        let interruptedNotification: Notification.Name = {
            #if compiler(>=6.0)
            return AVCaptureSession.wasInterruptedNotification
            #else
            return .AVCaptureSessionWasInterrupted
            #endif
        }()

        /// Observe AVCaptureSession interruptions and log reasons.
        NotificationCenter
            .default
            .publisher(for: interruptedNotification)
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
            .compactMap { $0 }
            .log(.debug, subsystems: .webRTC) { "CameraCapture session was interrupted with reason: \($0)." }
            .receive(on: processingQueue)
            .sink { _ in }
            .store(in: disposableBag)

        /// Observe end of AVCaptureSession interruptions and restart session if needed.
        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionInterruptionEnded)
            .log(.debug, subsystems: .webRTC) { _ in "CameraCapture session interruption ended." }
            .receive(on: processingQueue)
            .sink { [weak self] _ in self?.handleInterruptionEnded() }
            .store(in: disposableBag)

        state = .running(session: session, disposableBag: disposableBag)
    }

    /// Cleans up resources and resets state when camera capture stops.
    private func didStopCapture() {
        switch state {
        case .idle:
            break
        case let .running(_, disposableBag):
            disposableBag.removeAll()
            processingQueue.cancelAllOperations()
        }
        state = .idle
    }

    /// Restarts the session if it was interrupted and not running.
    private func handleInterruptionEnded() {
        switch state {
        case .idle:
            break
        case let .running(session, _):
            guard !session.isRunning else {
                return
            }
            session.startRunning()
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
