//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

protocol WebRTCPermissionsAdapterDelegate: AnyObject {
    func permissionsAdapter(
        _ permissionsAdapter: WebRTCPermissionsAdapter,
        audioOn: Bool
    )

    func permissionsAdapter(
        _ permissionsAdapter: WebRTCPermissionsAdapter,
        videoOn: Bool
    )
}

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

    init(_ delegate: WebRTCPermissionsAdapterDelegate) {
        self.delegate = delegate
        applicationStateAdapter
            .statePublisher
            .filter { $0 == .foreground }
            .removeDuplicates()
            .sink { [weak self] _ in self?.didMoveToForeground() }
            .store(in: disposableBag)
    }

    func willSet(callSettings: CallSettings) async -> CallSettings {
        do {
            return try await processingQueue.addSynchronousTaskOperation { [weak self] in
                guard let self else {
                    return callSettings
                }

                let updatedRequiredPermissions = {
                    var result = Set<RequiredPermission>()
                    if callSettings.audioOn { result.insert(.microphone) }
                    if callSettings.videoOn { result.insert(.camera) }
                    return result
                }()

                guard
                    requiredPermissions != updatedRequiredPermissions
                else {
                    return callSettings
                }

                switch applicationStateAdapter.state {
                case .foreground where shouldPrompt(for: updatedRequiredPermissions):
                    self.requiredPermissions = updatedRequiredPermissions
                    log.debug(
                        "Required permissions updated to:\(requiredPermissions)",
                        subsystems: .webRTC
                    )
                    log.debug(
                        "Application state is .foreground. Requesting permissions for:\(requiredPermissions)",
                        subsystems: .webRTC
                    )

                    _ = try await requestRequiredPermissions(invokeDelegate: false)
                case .foreground:
                    break
                default:
                    self.requiredPermissions = updatedRequiredPermissions
                    log.debug(
                        "Required permissions updated to:\(requiredPermissions)",
                        subsystems: .webRTC
                    )
                    log.debug(
                        "Application state is \(applicationStateAdapter.state) but we won't request for permissions:\(requiredPermissions).",
                        subsystems: .webRTC
                    )
                }

                var updatedCallSettings = callSettings
                if callSettings.audioOn, !permissions.hasMicrophonePermission {
                    updatedCallSettings = updatedCallSettings.withUpdatedAudioState(false)
                }

                if callSettings.videoOn, !permissions.hasCameraPermission {
                    updatedCallSettings = updatedCallSettings.withUpdatedVideoState(false)
                }
                return updatedCallSettings
            }
        } catch {
            log.error(error, subsystems: .webRTC)
            return callSettings
        }
    }

    // MARK: - Private Helpers

    private func didMoveToForeground() {
        processingQueue.addTaskOperation { [weak self] in
            guard
                let self,
                shouldPrompt(for: requiredPermissions)
            else {
                return
            }

            do {
                try await requestRequiredPermissions(invokeDelegate: true)
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
    }

    private func requestRequiredPermissions(invokeDelegate: Bool) async throws {
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
                let result = try await permissions.requestMicrophonePermission()
                if invokeDelegate {
                    delegate?.permissionsAdapter(self, audioOn: result)
                }
            case .camera:
                guard
                    !permissions.hasCameraPermission,
                    permissions.canRequestCameraPermission
                else {
                    continue
                }
                let result = try await permissions.requestCameraPermission()
                if invokeDelegate {
                    delegate?.permissionsAdapter(self, videoOn: result)
                }
            }
        }

        log.debug(
            "WebRTC completed request permissions for:\(Array(requiredPermissions)).",
            subsystems: .webRTC
        )

        requiredPermissions = []
    }

    private func shouldPrompt(for items: Set<RequiredPermission>) -> Bool {
        items.reduce(false) { partialResult, permission in
            guard
                !partialResult
            else {
                return partialResult
            }

            switch permission {
            case .microphone:
                return !permissions.hasMicrophonePermission && permissions.canRequestMicrophonePermission
            case .camera:
                return !permissions.hasCameraPermission && permissions.canRequestCameraPermission
            }
        }
    }
}
