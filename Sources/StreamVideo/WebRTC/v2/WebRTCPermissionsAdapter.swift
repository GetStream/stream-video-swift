//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Receives media toggles in response to permission changes.
protocol WebRTCPermissionsAdapterDelegate: AnyObject {
    /// Informs that microphone permission changed and audio should be toggled.
    ///
    /// - Parameters:
    ///   - permissionsAdapter: Sender instance.
    ///   - audioOn: `true` when microphone permission is granted.
    func permissionsAdapter(
        _ permissionsAdapter: WebRTCPermissionsAdapter,
        audioOn: Bool
    )

    /// Informs that camera permission changed and video should be toggled.
    ///
    /// - Parameters:
    ///   - permissionsAdapter: Sender instance.
    ///   - videoOn: `true` when camera permission is granted.
    func permissionsAdapter(
        _ permissionsAdapter: WebRTCPermissionsAdapter,
        videoOn: Bool
    )
}

/// Coordinates permission prompts and aligns call media with user grants.
///
/// Prompts are deferred until the application is in the foreground and the
/// WebRTC coordinator has reached the `.joined` stage. Work is serialized to
/// avoid races across app state and permission updates.
final class WebRTCPermissionsAdapter: @unchecked Sendable {
    private enum RequiredPermission: CustomStringConvertible {
        case microphone, camera
        var description: String {
            switch self {
            case .microphone:
                return ".microphone"
            case .camera:
                return ".camera"
            }
        }
    }

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    @Injected(\.permissions) private var permissions

    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    private weak var delegate: WebRTCPermissionsAdapterDelegate?
    private var requiredPermissions: Set<RequiredPermission> = []
    private var canPromptForPermissions: Bool = false

    /// Creates an adapter and begins observing app/permission changes.
    ///
    /// - Parameters:
    ///   - delegate: Target for audio/video enable updates.
    ///   - stagePublisher: Publishes WebRTC stage transitions so prompts can
    ///     wait until the call is fully joined.
    init(
        _ delegate: WebRTCPermissionsAdapterDelegate,
        stagePublisher: AnyPublisher<WebRTCCoordinator.StateMachine.Stage.ID, Never>
    ) {
        self.delegate = delegate

        Publishers.CombineLatest(
            stagePublisher
                .removeDuplicates()
                .eraseToAnyPublisher(),
            applicationStateAdapter
                .statePublisher
                .filter { $0 == .foreground }
                .removeDuplicates()
        ).sink { [weak self] stageID, _ in
            self?.process(canPromptForPermissions: stageID == .joined)
        }
        .store(in: disposableBag)

        permissions
            .$hasMicrophonePermission
            .removeDuplicates()
            .log(.debug) { "Received microphone permission updated to granted:\($0)" }
            .sink { [weak self] in self?.didUpdateMicrophonePermission($0) }
            .store(in: disposableBag)

        permissions
            .$hasCameraPermission
            .removeDuplicates()
            .log(.debug) { "Received camera permission updated to granted:\($0)" }
            .sink { [weak self] in self?.didUpdateCameraPermission($0) }
            .store(in: disposableBag)
    }

    /// Reconciles requested media state with current permissions.
    ///
    /// Prompts when in foreground and needed; disables tracks in the returned
    /// settings if permission is missing.
    ///
    /// - Parameter callSettings: Desired media settings for the call.
    /// - Returns: Settings adjusted to granted permissions.
    func willSet(callSettings: CallSettings) async -> CallSettings {
        do {
            return try await processingQueue.addSynchronousTaskOperation { [weak self] in
                guard
                    let self,
                    // We only need to check if any of the camera or mic
                    // permissions are not granted. Otherwise we don't need
                    // to perform any operation.
                    !permissions.hasCameraPermission || !permissions.hasMicrophonePermission
                else {
                    return callSettings
                }

                let updatedRequiredPermissions = {
                    var result = Set<RequiredPermission>()
                    if callSettings.audioOn { result.insert(.microphone) }
                    if callSettings.videoOn { result.insert(.camera) }
                    return result
                }()

                if requiredPermissions != updatedRequiredPermissions {
                    self.requiredPermissions = updatedRequiredPermissions
                    
                    switch applicationStateAdapter.state {
                    case .foreground where shouldPrompt(for: updatedRequiredPermissions):
                        log.debug(
                            "Required permissions updated to:\(requiredPermissions)",
                            subsystems: .webRTC
                        )
                        log.debug(
                            "Application state is .foreground. Requesting permissions for:\(requiredPermissions)",
                            subsystems: .webRTC
                        )

                        _ = try await requestRequiredPermissions()
                    case .foreground:
                        break
                    default:
                        log.debug(
                            "Required permissions updated to:\(requiredPermissions)",
                            subsystems: .webRTC
                        )
                        log.debug(
                            "Application state is \(applicationStateAdapter.state) but we won't request for permissions:\(requiredPermissions).",
                            subsystems: .webRTC
                        )
                    }
                }

                var updatedCallSettings = callSettings
                if callSettings.audioOn, permissions.state.microphonePermission != .granted {
                    updatedCallSettings = updatedCallSettings.withUpdatedAudioState(false)
                }

                if callSettings.videoOn, permissions.state.cameraPermission != .granted {
                    updatedCallSettings = updatedCallSettings.withUpdatedVideoState(false)
                }

                return updatedCallSettings
            }
        } catch {
            log.error(error, subsystems: .webRTC)
            return callSettings
        }
    }

    func cleanUp() {
        processingQueue.addOperation { [weak self] in
            // By emptying the Set we are saying that there are no permissions
            // required, so when the app moves to foreground no prompts will
            // appear.
            self?.requiredPermissions = []
        }
    }

    // MARK: - Private Helpers

    /// Re-evaluates pending permissions after a stage or app-state change.
    ///
    /// Prompts are only issued once both gating conditions are met: the app is
    /// in the foreground and the coordinator is already joined.
    private func process(canPromptForPermissions: Bool) {
        processingQueue.addTaskOperation { [weak self] in
            guard
                let self
            else {
                return
            }

            self.canPromptForPermissions = canPromptForPermissions

            guard
                shouldPrompt(for: requiredPermissions)
            else {
                return
            }

            do {
                try await requestRequiredPermissions()
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
    }

    /// Requests missing, requestable permissions.
    ///
    /// - Throws: Errors thrown by the permission APIs.
    private func requestRequiredPermissions() async throws {
        guard
            shouldPrompt(for: requiredPermissions)
        else {
            return
        }

        log.debug(
            "WebRTC will request permissions for:\(Array(requiredPermissions)).",
            subsystems: .webRTC
        )

        for requiredPermission in requiredPermissions {
            switch requiredPermission {
            case .microphone:
                guard
                    !permissions.hasMicrophonePermission,
                    permissions.canRequestMicrophonePermission
                else {
                    continue
                }
                _ = try await permissions.requestMicrophonePermission()
            case .camera:
                guard
                    !permissions.hasCameraPermission,
                    permissions.canRequestCameraPermission
                else {
                    continue
                }
                _ = try await permissions.requestCameraPermission()
            }
        }

        log.debug(
            "WebRTC completed request permissions for:\(Array(requiredPermissions)).",
            subsystems: .webRTC
        )
    }

    /// Returns `true` if at least one permission in the set can be requested.
    private func shouldPrompt(for items: Set<RequiredPermission>) -> Bool {
        items.reduce(false) { partialResult, permission in
            guard
                !partialResult
            else {
                return partialResult
            }

            switch permission {
            case .microphone:
                return !permissions.hasMicrophonePermission && permissions.canRequestMicrophonePermission && canPromptForPermissions
            case .camera:
                return !permissions.hasCameraPermission && permissions.canRequestCameraPermission && canPromptForPermissions
            }
        }
    }

    /// Applies microphone permission updates and notifies the delegate.
    private func didUpdateMicrophonePermission(_ hasPermission: Bool) {
        processingQueue.addOperation { [weak self] in
            guard let self, requiredPermissions.contains(.microphone) else {
                return
            }
            delegate?.permissionsAdapter(self, audioOn: hasPermission)
            requiredPermissions.remove(.microphone)
        }
    }

    /// Applies camera permission updates and notifies the delegate.
    private func didUpdateCameraPermission(_ hasPermission: Bool) {
        processingQueue.addOperation { [weak self] in
            guard let self, requiredPermissions.contains(.camera) else {
                return
            }
            delegate?.permissionsAdapter(self, videoOn: hasPermission)
            requiredPermissions.remove(.camera)
        }
    }
}
