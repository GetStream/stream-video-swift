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
    @Atomic private(set) var activeCallSettings: CallSettings? {
        didSet {
            guard activeCallSettings != oldValue else {
                return
            }
            didUpdate(activeCallSettings)
        }
    }

    /// The delegate for receiving audio session events, such as call settings
    /// updates.
    weak var delegate: StreamAudioSessionAdapterDelegate?

    /// Initializes a new `StreamAudioSessionAdapter` instance, configuring
    /// the session with default settings and enabling manual audio control
    /// for WebRTC.w
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
            try $0.setConfiguration(configuration)
            log.debug(
                "AudioSession updated \(configuration)",
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
        activeCallSettings = settings
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
        log.debug(
            "AudioSession didChangeRoute reason:\(reason) currentRoute:\(session.currentRoute) previousRoute:\(previousRoute).",
            subsystems: .audioSession
        )
        
        guard let activeCallSettings else {
            return
        }

        switch (activeCallSettings.speakerOn, session.currentRoute.isSpeaker) {
        case (true, false):
            delegate?.audioSessionAdapterDidUpdateCallSettings(
                self,
                callSettings: activeCallSettings.withUpdatedSpeakerState(false)
            )

        case (false, true):
            delegate?.audioSessionAdapterDidUpdateCallSettings(
                self,
                callSettings: activeCallSettings.withUpdatedSpeakerState(true)
            )

        default:
            break
        }

//        switch reason {
//        case .unknown:
//            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
//        case .newDeviceAvailable:
//            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
//        case .oldDeviceUnavailable:
//            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
//        case .categoryChange:
//            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
//        case .override:
//            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
//        case .wakeFromSleep:
//            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
//        case .noSuitableRouteForCategory:
//            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
//        case .routeConfigurationChange:
//            performSpeakerUpdateAction(.respectCallSettings(activeCallSettings))
//        @unknown default:
//            performSpeakerUpdateAction(.routeUpdate(activeCallSettings))
//        }
    }

    // MARK: - Private helpers

    private func didUpdate(_ callSettings: CallSettings?) {
        performSpeakerUpdateAction(callSettings)

        log.debug(
            "AudioSession updated with \(callSettings?.description ?? "nil")",
            subsystems: .audioSession
        )
    }

    /// Executes an action to update the speaker routing based on current
    /// call settings.
    /// - Parameter action: The action to perform, affecting routing.
    private func performSpeakerUpdateAction(_ callSettings: CallSettings?) {
        let overridePort: AVAudioSession.PortOverride = callSettings?.speakerOn == true
            ? .speaker
            : .none

        audioSession.updateConfiguration(
            functionName: #function,
            file: #file,
            line: #line
        ) {
            do {
                switch overridePort {
                case .none:
                    try $0.setMode(.voiceChat)
                case .speaker:
                    try $0.setMode(.videoChat)
                @unknown default:
                    break
                }
            } catch {
                log.error(error, subsystems: .audioSession)
            }
            try $0.overrideOutputAudioPort(overridePort)
        }
    }
}

extension RTCAudioSessionConfiguration: ReflectiveStringConvertible {}
