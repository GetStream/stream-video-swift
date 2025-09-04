//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

protocol WebRTCPermissionsAdapterDelegate: AnyObject {
    func webrtcApplicationDidBecomeActive(audioOn: Bool, videoOn: Bool)
}

final class WebRTCPermissionsAdapter: @unchecked Sendable {

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    @Injected(\.permissions) private var permissions
    @Injected(\.audioStore) private var audioStore

    private weak var delegate: WebRTCPermissionsAdapterDelegate?

    private let disposableBag = DisposableBag()
    private var shouldRequestMicrophonePermission: Bool = false
    private var shouldRequestCameraPermission: Bool = false

    init(_ delegate: WebRTCPermissionsAdapterDelegate) {
        self.delegate = delegate

        applicationStateAdapter
            .statePublisher
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdateApplicationState($0) }
            .store(in: disposableBag)
    }

    func updateRequestedCallSettings(
        _ callSettings: CallSettings
    ) async throws -> CallSettings {
        switch applicationStateAdapter.state {
        case .foreground:
            return callSettings

        case .background, .unknown:
            var updatedCallSettings = callSettings

            if updatedCallSettings.audioOn, !permissions.hasMicrophonePermission {
                if permissions.canRequestMicrophonePermission, !shouldRequestMicrophonePermission {
                    shouldRequestMicrophonePermission = true
                    log
                        .debug(
                            "Microphone permission will be requested once the app becomes active.",
                            subsystems: .webRTC
                        )
                }

                updatedCallSettings = updatedCallSettings
                    .withUpdatedAudioState(false)
            } else {
                shouldRequestCameraPermission = false
            }

            if updatedCallSettings.videoOn, !permissions.hasCameraPermission {
                if permissions.canRequestCameraPermission, !shouldRequestCameraPermission {
                    shouldRequestCameraPermission = true
                    log
                        .debug(
                            "Camera permission will be requested once the app becomes active.",
                            subsystems: .webRTC
                        )
                }

                updatedCallSettings = updatedCallSettings
                    .withUpdatedVideoState(false)
            } else {
                shouldRequestCameraPermission = false
            }

            return updatedCallSettings
        }
    }

    // MARK: - Private Helpers

    private func didUpdateApplicationState(_ applicationState: ApplicationState) {
        guard
            applicationState == .foreground, shouldRequestMicrophonePermission || shouldRequestCameraPermission
        else {
            return
        }

        Task { [weak self] in
            guard let self else {
                return
            }

            log.debug(
                "Application became active and we will request permissions for microphone:\(shouldRequestMicrophonePermission) camera:\(shouldRequestCameraPermission)",
                subsystems: .webRTC
            )

            if shouldRequestMicrophonePermission {
                log.debug("Requesting microphone permission.", subsystems: .webRTC)
                let result = try await permissions.requestMicrophonePermission()
                log.debug("Microphone permission request completed with result:\(result).", subsystems: .webRTC)
            }

            if shouldRequestCameraPermission {
                log.debug("Requesting camera permission.", subsystems: .webRTC)
                let result = try await permissions.requestCameraPermission()
                log.debug("Camera permission request completed with result:\(result).", subsystems: .webRTC)
            }

            log.debug("Restarting audioSession started.")
            do {
                try await audioStore.restartAudioSessionSync()
            } catch {
                log.error(error, subsystems: .audioSession)
            }
            log.debug("Restarting audioSession completed.")

            delegate?.webrtcApplicationDidBecomeActive(
                audioOn: shouldRequestMicrophonePermission,
                videoOn: shouldRequestCameraPermission
            )
        }
    }
}
