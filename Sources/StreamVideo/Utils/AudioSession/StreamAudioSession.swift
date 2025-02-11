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
final class StreamAudioSession: @unchecked Sendable, ObservableObject {

    private var currentDevice = CurrentDevice.currentValue

    private var audioRouteChangeCancellable: AnyCancellable?
    /// The shared audio session instance conforming to `AudioSessionProtocol`
    /// that manages WebRTC audio settings.
    private let audioSession: StreamRTCAudioSession = .init()
    private var hasBeenConfigured = false

    /// The current active call settings, or `nil` if no active call is in session.
    @Atomic private(set) var activeCallSettings: CallSettings
    @Atomic private(set) var ownCapabilities: Set<OwnCapability>
    @Atomic private(set) var policy: AudioSessionPolicy

    var categoryPublisher: AnyPublisher<AVAudioSession.Category, Never> {
        audioSession.$state.map(\.category).eraseToAnyPublisher()
    }

    /// The delegate for receiving audio session events, such as call settings
    /// updates.
    weak var delegate: StreamAudioSessionAdapterDelegate?

    // MARK: - AudioSession State

    @Published var isRecording: Bool = false

    var isActive: Bool { audioSession.isActive }

    var currentRoute: AVAudioSessionRouteDescription { audioSession.currentRoute }

    /// Initializes a new `StreamAudioSessionAdapter` instance, configuring
    /// the session with default settings and enabling manual audio control
    /// for WebRTC.w
    /// - Parameter audioSession: An `AudioSessionProtocol` instance. Defaults
    ///   to `StreamRTCAudioSession`.
    required init(
        callSettings: CallSettings = .init(),
        ownCapabilities: Set<OwnCapability> = [],
        policy: AudioSessionPolicy = DefaultAudioSessionPolicy()
    ) {
        activeCallSettings = callSettings
        self.ownCapabilities = ownCapabilities
        self.policy = policy

        /// Update the active call's `audioSession` to make available to other components.
        Self.currentValue = self

        audioSession.useManualAudio = true
        audioSession.isAudioEnabled = true

        audioRouteChangeCancellable = audioSession
            .eventPublisher
            .compactMap {
                switch $0 {
                case let .didChangeRoute(session, reason, previousRoute):
                    return (session, reason, previousRoute)
                default:
                    return nil
                }
            }
            .log(.debug, subsystems: .audioSession) { [weak self] session, reason, previousRoute in
                """
                AudioSession didChangeRoute reason:\(reason)
                - isRecording: \(self?.isRecording.description ?? "-")
                - category: \(AVAudioSession.Category(rawValue: session.category))
                - mode: \(AVAudioSession.Mode(rawValue: session.mode))
                - categoryOptions: \(session.categoryOptions)
                - currentRoute:\(session.currentRoute)
                - previousRoute:\(previousRoute)
                """
            }
            .sink { [weak self] in
                self?.audioSessionDidChangeRoute(
                    $0,
                    reason: $1,
                    previousRoute: $2
                )
            }
    }

    nonisolated func dismantle() {
        audioRouteChangeCancellable?.cancel()
        audioRouteChangeCancellable = nil
        if Self.currentValue === self {
            // Reset activeCall audioSession.
            Self.currentValue = nil
        }
    }

    // MARK: - OwnCapabilities

    /// Updates the audio session with new call settings.
    /// - Parameter settings: The new `CallSettings` to apply.
    func didUpdateOwnCapabilities(
        _ ownCapabilities: Set<OwnCapability>
    ) async throws {
        self.ownCapabilities = ownCapabilities
        try await didUpdate(
            callSettings: activeCallSettings,
            ownCapabilities: ownCapabilities
        )
    }

    // MARK: - CallSettings

    /// Updates the audio session with new call settings.
    /// - Parameter settings: The new `CallSettings` to apply.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        activeCallSettings = settings
        try await didUpdate(
            callSettings: settings,
            ownCapabilities: ownCapabilities
        )
    }

    // MARK: - Policy

    func didUpdatePolicy(
        _ policy: AudioSessionPolicy
    ) {
        self.policy = policy
    }

    // MARK: - Recording

    func prepareForRecording() async throws {
        guard !activeCallSettings.audioOn else {
            return
        }

        activeCallSettings = activeCallSettings.withUpdatedAudioState(true)
        try await didUpdate(
            callSettings: activeCallSettings,
            ownCapabilities: ownCapabilities
        )
        log.debug(
            "AudioSession completed preparation for recording.",
            subsystems: .audioSession
        )
    }

    func requestRecordPermission() async -> Bool {
        let result = await audioSession.requestRecordPermission()
        log.debug(
            "AudioSession completed request for recording permission.",
            subsystems: .audioSession
        )
        return result
    }

    // MARK: - Private helpers

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
    private func audioSessionDidChangeRoute(
        _ session: RTCAudioSession,
        reason: AVAudioSession.RouteChangeReason,
        previousRoute: AVAudioSessionRouteDescription
    ) {
        guard currentDevice.deviceType == .phone else {
            if activeCallSettings.speakerOn != session.currentRoute.isSpeaker {
                log.warning(
                    "AudioSession cannot be switched to speakerOn:\(activeCallSettings.speakerOn) as the current device doesn't have an earpiece. Changing back CallSettings to speakOn:\(session.currentRoute.isSpeaker)",
                    subsystems: .audioSession
                )
                delegate?.audioSessionAdapterDidUpdateCallSettings(
                    self,
                    callSettings: activeCallSettings
                        .withUpdatedSpeakerState(session.currentRoute.isSpeaker)
                )
            }
            return
        }

        switch (activeCallSettings.speakerOn, session.currentRoute.isSpeaker) {
        case (true, false):
            delegate?.audioSessionAdapterDidUpdateCallSettings(
                self,
                callSettings: activeCallSettings.withUpdatedSpeakerState(false)
            )

        case (false, true) where session.category == AVAudioSession.Category.playAndRecord.rawValue:
            delegate?.audioSessionAdapterDidUpdateCallSettings(
                self,
                callSettings: activeCallSettings.withUpdatedSpeakerState(true)
            )

        default:
            break
        }
    }

    private func configureAudioSession(
        settings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        file: StaticString,
        functionName: StaticString,
        line: UInt
    ) async throws {
        let configuration = settings.audioSessionConfiguration

        try await audioSession.setCategory(
            .init(rawValue: configuration.category),
            mode: .init(rawValue: configuration.mode),
            with: configuration.categoryOptions
        )

        hasBeenConfigured = true
        log.debug(
            "AudioSession was configured with \(configuration)",
            subsystems: .audioSession,
            functionName: functionName,
            fileName: file,
            lineNumber: line
        )
    }

    private func didUpdate(
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) async throws {
        log.debug(
            "Will reconfigure audio session with settings: \(callSettings) ownCapabilities:\(ownCapabilities) policy:\(type(of: policy)).",
            subsystems: .audioSession
        )

        guard hasBeenConfigured else {
            try await configureAudioSession(
                settings: callSettings,
                ownCapabilities: ownCapabilities,
                file: file,
                functionName: functionName,
                line: line
            )
            return
        }

//        let currentDeviceHasEarpiece = currentDevice.deviceType == .phone
//
//        let category: AVAudioSession.Category = callSettings.audioOn
//            || (callSettings.speakerOn && currentDeviceHasEarpiece)
//            ? .playAndRecord
//            : .playback
//
//        let mode: AVAudioSession.Mode = category == .playAndRecord
//        ? callSettings.speakerOn == true ? .videoChat : .voiceChat
//            : .default
//
//        let categoryOptions: AVAudioSession.CategoryOptions = category == .playAndRecord
//            ? .playAndRecord
//            : .playback
//
//        let overridePort: AVAudioSession.PortOverride? = category == .playAndRecord
//            ? callSettings.speakerOn == true ? .speaker : AVAudioSession.PortOverride.none
//            : nil
//
//        let configuration = AudioSessionConfiguration(
//            category: category,
//            mode: mode,
//            options: categoryOptions,
//            overrideOutputAudioPort: overridePort
//        )

        let configuration = policy.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        if configuration.category == .playback, isRecording {
            log.debug(
                "Will defer execution until recording has stopped.",
                subsystems: .audioSession,
                functionName: functionName,
                fileName: file,
                lineNumber: line
            )
            await deferExecutionUntilRecordingIsStopped()
        }

        if
            configuration.overrideOutputAudioPort == nil,
            audioSession.state.category == AVAudioSession.Category.playAndRecord
        {
            try await audioSession.overrideOutputAudioPort(.none)
        }

        do {
            try await audioSession.setCategory(
                configuration.category,
                mode: configuration.mode,
                with: configuration.options
            )
        } catch {
            log.error(
                "Failed while setting category:\(configuration.category) mode:\(configuration.mode) options:\(configuration.options)",
                subsystems: .audioSession,
                error: error,
                functionName: functionName,
                fileName: file,
                lineNumber: line
            )
        }

        if let overrideOutputAudioPort = configuration.overrideOutputAudioPort {
            try await audioSession.overrideOutputAudioPort(overrideOutputAudioPort)
        }

        log.debug(
            "AudioSession updated with state \(audioSession.state)",
            subsystems: .audioSession,
            functionName: functionName,
            fileName: file,
            lineNumber: line
        )
    }

    private func deferExecutionUntilRecordingIsStopped() async {
        do {
            _ = try await $isRecording
                .filter { $0 == false }
                .nextValue(timeout: 1)
            try await Task.sleep(nanoseconds: 250 * 1_000_000)
        } catch {
            log.error(
                "Defer execution until recording has stopped failed.",
                subsystems: .audioSession,
                error: error
            )
        }
    }
}

/// A key for dependency injection of an `AudioSessionProtocol` instance
/// that represents the active call audio session.
extension StreamAudioSession: InjectionKey {
    static var currentValue: StreamAudioSession?
}

extension InjectedValues {
    /// The active call's audio session. The value is being set on `StreamAudioSession`
    /// `init` / `deinit`
    var activeCallAudioSession: StreamAudioSession? {
        get {
            Self[StreamAudioSession.self]
        }
        set {
            Self[StreamAudioSession.self] = newValue
        }
    }
}
