//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// The `StreamAudioSessionAdapter` class manages the device's audio session
/// for an app, enabling control over activation, configuration, and routing
/// to output devices like speakers and in-ear speakers.
final class StreamAudioSessionAdapter: NSObject, RTCAudioSessionDelegate, @unchecked Sendable {

    /// An enum defining actions to update speaker routing based on call settings.
    private enum SpeakerAction {
        case routeUpdate(CallSettings)
        case respectCallSettings(CallSettings)
    }

    /// The shared audio session instance conforming to `AudioSessionProtocol`
    /// that manages WebRTC audio settings.
    private let audioSession: AudioSessionProtocol

    /// The current active call settings, or `nil` if no active call is in session.
    @Atomic private(set) var activeCallSettings: CallSettings?

    /// The delegate for receiving audio session events, such as call settings
    /// updates.
    weak var delegate: StreamAudioSessionAdapterDelegate?

    /// Initializes a new `StreamAudioSessionAdapter` instance, configuring
    /// the session with default settings and enabling manual audio control
    /// for WebRTC.
    /// - Parameter audioSession: An `AudioSessionProtocol` instance. Defaults
    ///   to `StreamRTCAudioSession`.
    required init(_ audioSession: AudioSessionProtocol = StreamRTCAudioSession()) {
        self.audioSession = audioSession
        super.init()

        /// Update the active call's `audioSession` to make available to other components.
        StreamActiveCallAudioSessionKey.currentValue = audioSession

        audioSession.add(self)
        audioSession.useManualAudio = true
        audioSession.isAudioEnabled = true

        let configuration = RTCAudioSessionConfiguration.default
        audioSession.updateConfiguration(
            functionName: #function,
            file: #fileID,
            line: #line
        ) {
            try $0.setConfiguration(.default)
            log.debug(
                "AudioSession updated configuration with category: \(configuration.category) options: \(configuration.categoryOptions) mode: \(configuration.mode)",
                subsystems: .audioSession
            )
        }
    }

    deinit {
        if StreamActiveCallAudioSessionKey.currentValue === audioSession {
            // Reset activeCall audioSession.
            StreamActiveCallAudioSessionKey.currentValue = nil
        }
    }

    // MARK: - CallSettings

    /// Updates the audio session with new call settings.
    /// - Parameter settings: The new `CallSettings` to apply.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) {
        guard settings != activeCallSettings else { return }

        performSessionAction(settings.audioOutputOn)
        performSpeakerUpdateAction(.respectCallSettings(settings))
        activeCallSettings = settings

        log.debug(
            "AudioSession updated isActive:\(settings.audioOutputOn) speakerOn:\(settings.speakerOn).",
            subsystems: .audioSession
        )
    }

    // MARK: - RTCAudioSessionDelegate

    /// Handles audio route changes, updating the session based on the reason
    /// for the change.
    ///
    /// For cases like `.newDeviceAvailable`, `.override`,
    /// `.noSuitableRouteForCategory`, `.routeConfigurationChange`, `.default`,
    /// or `.unknown`, the route change is accepted, and the `CallSettings`
    /// are updated accordingly, triggering a delegate update.
    ///
    /// For other cases, the route change is ignored, enforcing the existing
    /// `CallSettings`.
    ///
    /// - Parameters:
    ///   - session: The `RTCAudioSession` instance.
    ///   - reason: The reason for the route change.
    ///   - previousRoute: The previous audio route configuration.
    func audioSessionDidChangeRoute(
        _ session: RTCAudioSession,
        reason: AVAudioSession.RouteChangeReason,
        previousRoute: AVAudioSessionRouteDescription
    ) {
        guard let activeCallSettings else {
            return
        }

        switch reason {
        case .unknown:
            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
        case .newDeviceAvailable:
            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
        case .oldDeviceUnavailable:
            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
        case .categoryChange:
            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
        case .override:
            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
        case .wakeFromSleep:
            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
        case .noSuitableRouteForCategory:
            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
        case .routeConfigurationChange:
            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
        @unknown default:
            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
        }
    }

    /// Logs the status when the session can play or record.
    /// - Parameters:
    ///   - session: The `RTCAudioSession` instance.
    ///   - canPlayOrRecord: A Boolean indicating whether play or record
    ///     capabilities are available.
    func audioSession(
        _ session: RTCAudioSession,
        didChangeCanPlayOrRecord canPlayOrRecord: Bool
    ) {
        log.info(
            "AudioSession can playOrRecord:\(canPlayOrRecord).",
            subsystems: .audioSession
        )
    }

    /// Logs when the session stops playing or recording.
    /// - Parameter session: The `RTCAudioSession` instance.
    func audioSessionDidStopPlayOrRecord(
        _ session: RTCAudioSession
    ) { log.info("AudioSession cannot playOrRecord.", subsystems: .audioSession) }

    /// Configures the session's active state when it changes.
    /// - Parameters:
    ///   - audioSession: The `RTCAudioSession` instance.
    ///   - active: A Boolean indicating the desired active state.
    func audioSession(
        _ audioSession: RTCAudioSession,
        didSetActive active: Bool
    ) {
        guard let activeCallSettings else { return }
        performSessionAction(active)
        performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
    }

    /// Logs and manages failure when setting the active state.
    /// - Parameters:
    ///   - audioSession: The `RTCAudioSession` instance.
    ///   - active: The desired active state.
    ///   - error: The error encountered during the state change.
    func audioSession(
        _ audioSession: RTCAudioSession,
        failedToSetActive active: Bool,
        error: any Error
    ) {
        log.error(
            "AudioSession failedToSetActive active:\(active)",
            subsystems: .audioSession,
            error: error
        )
        performSessionAction(false)
    }

    /// Handles failure in starting audio unit playback or recording.
    /// - Parameters:
    ///   - audioSession: The `RTCAudioSession` instance.
    ///   - error: The error encountered during startup.
    func audioSession(
        _ audioSession: RTCAudioSession,
        audioUnitStartFailedWithError error: any Error
    ) {
        log.error(
            "AudioSession audioUnitStartFailedWithError",
            subsystems: .audioSession,
            error: error
        )
        performSessionAction(false)
    }

    // MARK: - Private helpers

    /// Executes an action to update the speaker routing based on current
    /// call settings.
    /// - Parameter action: The action to perform, affecting routing.
    private func performSpeakerUpdateAction(_ action: SpeakerAction) {
        switch action {
        case let .routeUpdate(currentCallSettings):
            let updatedCallSettings = currentCallSettings
                .withUpdatedSpeakerState(audioSession.isUsingSpeakerOutput)

            guard currentCallSettings != updatedCallSettings else {
                return
            }

            delegate?.audioSessionAdapterDidUpdateCallSettings(
                self,
                callSettings: updatedCallSettings
            )
            log.debug(
                "AudioSession route requires speaker update \(currentCallSettings.speakerOn) → \(updatedCallSettings.speakerOn).",
                subsystems: .audioSession
            )

        case let .respectCallSettings(currentCallSettings):
            if audioSession.isUsingSpeakerOutput != currentCallSettings.speakerOn {
                let category = audioSession.category
                let categoryOptions: AVAudioSession.CategoryOptions = currentCallSettings.speakerOn
                    ? [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
                    : [.allowBluetooth, .allowBluetoothA2DP]

                let mode: AVAudioSession.Mode = currentCallSettings.speakerOn
                    ? .videoChat
                    : .voiceChat

                let overrideOutputAudioPort: AVAudioSession.PortOverride = currentCallSettings.speakerOn
                    ? .speaker
                    : .none

                audioSession.updateConfiguration(
                    functionName: #function,
                    file: #fileID,
                    line: #line
                ) {
                    try $0.setMode(mode.rawValue)
                    try $0.setCategory(category, with: categoryOptions)
                    try $0.overrideOutputAudioPort(overrideOutputAudioPort)

                    log.debug(
                        "AudioSession updated mode:\(mode.rawValue) category:\(category)  options:\(categoryOptions) overrideOutputAudioPort:\(overrideOutputAudioPort == .speaker ? ".speaker" : ".none")",
                        subsystems: .audioSession
                    )
                }
            }
        }
    }

    /// Updates the active state of the session.
    /// - Parameter isActive: A Boolean indicating if the session should be
    ///   active.
    private func performSessionAction(_ isActive: Bool) {
        guard audioSession.isActive != isActive else {
            return
        }
        log.debug(
            "AudioSession will attempt to set isActive:\(isActive).",
            subsystems: .audioSession
        )
        audioSession.updateConfiguration(
            functionName: #function,
            file: #fileID,
            line: #line
        ) { try $0.setActive(isActive) }
    }
}
