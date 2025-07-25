//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// Manages the app’s audio session, handling activation, configuration,
/// and routing to output devices such as speakers and in-ear speakers.
final class StreamAudioSession: @unchecked Sendable, ObservableObject {

    /// The last applied audio session configuration.
    private var lastUsedConfiguration: AudioSessionConfiguration?

    /// The current device as is being described by ``UIUserInterfaceIdiom``.
    private let currentDevice = CurrentDevice.currentValue

    /// The WebRTC-compatible audio session.
    private let audioSession: AudioSessionProtocol

    /// Serial execution queue for processing session updates.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    /// A disposable bag holding all observation cancellable.
    private let disposableBag = DisposableBag()

    /// The time to wait for recording to be stopped before we attempt to set the category to `.playback`
    private let deferExecutionDueToRecordingInterval: TimeInterval = 1

    /// The current call settings, or `nil` if no active call exists.
    @Atomic private(set) var activeCallSettings: CallSettings

    /// The set of the user's own audio capabilities.
    @Atomic private(set) var ownCapabilities: Set<OwnCapability>

    /// The policy defining audio session behavior.
    @Atomic private(set) var policy: AudioSessionPolicy

    /// Published property to track the audio session category.
    @Published private(set) var category: AVAudioSession.Category

    /// Delegate for handling audio session events.
    weak var delegate: StreamAudioSessionAdapterDelegate?

    // MARK: - AudioSession State

    /// Indicates whether the session is recording.
    @Published var isRecording: Bool = false

    /// Checks if the audio session is currently active.
    var isActive: Bool { audioSession.isActive }

    /// Retrieves the current audio route description.
    var currentRoute: AVAudioSessionRouteDescription { audioSession.currentRoute }

    private let audioDeviceModule: RTCAudioDeviceModule

    /// Initializes a new `StreamAudioSessionAdapter` instance, configuring
    /// the session with default settings and enabling manual audio control
    /// for WebRTC.
    ///
    /// - Parameter callSettings: The settings for the current call.
    /// - Parameter ownCapabilities: The set of the user's own audio
    ///   capabilities.
    /// - Parameter policy: The policy defining audio session behavior.
    /// - Parameter audioSession: An `AudioSessionProtocol` instance. Defaults
    ///   to `StreamRTCAudioSession`.
    required init(
        callSettings: CallSettings = .init(),
        ownCapabilities: Set<OwnCapability> = [],
        policy: AudioSessionPolicy = DefaultAudioSessionPolicy(),
        audioSession: AudioSessionProtocol = StreamRTCAudioSession(),
        audioDeviceModule: RTCAudioDeviceModule
    ) {
        activeCallSettings = callSettings
        self.ownCapabilities = ownCapabilities
        self.policy = policy
        self.audioSession = audioSession
        category = audioSession.category
        self.audioDeviceModule = audioDeviceModule

        /// Update the active call's `audioSession` to make available to
        /// other components.
        Self.currentValue = self

        var audioSession = self.audioSession
        audioSession.useManualAudio = true
        audioSession.isAudioEnabled = true

        audioSession
            .eventPublisher
            .compactMap {
                guard case let .didChangeRoute(session, reason, previousRoute) = $0 else {
                    return nil
                }
                return (session, reason, previousRoute)
            }
            .filter { $0.0.isActive }
            .log(.debug, subsystems: .audioSession) { [weak self] session, reason, previousRoute in
                """
                AudioSession didChangeRoute reason:\(reason)
                - isActive: \(session.isActive)
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
            .store(in: disposableBag)

        if let streamAudioSession = audioSession as? StreamRTCAudioSession {
            streamAudioSession
                .$state
                .map(\.category)
                .assign(to: \.category, onWeak: self)
                .store(in: disposableBag)
        }
    }

    /// Removes all observers and resets the active audio session.
    nonisolated func dismantle() {
        disposableBag.removeAll()
        if Self.currentValue === self {
            // Reset activeCall audioSession.
            Self.currentValue = nil
        }
    }

    func callKitActivated(_ audioSession: AVAudioSessionProtocol) throws {
        let configuration = policy.configuration(
            for: activeCallSettings,
            ownCapabilities: ownCapabilities
        )

        try audioSession.setCategory(
            configuration.category,
            mode: configuration.mode,
            with: configuration.options
        )

        if let overrideOutputAudioPort = configuration.overrideOutputAudioPort {
            try audioSession.setOverrideOutputAudioPort(overrideOutputAudioPort)
        } else {
            try audioSession.setOverrideOutputAudioPort(.none)
        }
    }

    // MARK: - OwnCapabilities

    /// Updates the audio session with new call settings.
    ///
    /// - Parameter ownCapabilities: The new set of `OwnCapability` to apply.
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
    ///
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

    /// Updates the audio session with a new policy.
    ///
    /// - Parameter policy: The new `AudioSessionPolicy` to apply.
    func didUpdatePolicy(
        _ policy: AudioSessionPolicy
    ) async throws {
        self.policy = policy
        try await didUpdate(
            callSettings: activeCallSettings,
            ownCapabilities: ownCapabilities
        )
    }

    // MARK: - Recording

    /// Prepares the audio session for recording.
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

    /// Requests the record permission from the user.
    func requestRecordPermission() async -> Bool {
        guard !isRecording else {
            return isRecording
        }
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
        guard session.isActive else {
            return
        }

        guard session.category == category.rawValue else {
            log.warning(
                """
                AudioSession category mismatch between AVAudioSession & SDK:
                - AVAudioSession.category: \(AVAudioSession.Category(rawValue: session.category))
                - SDK: \(category)
                """,
                subsystems: .audioSession
            )
            return
        }

        guard currentDevice.deviceType == .phone else {
            if activeCallSettings.speakerOn != session.currentRoute.isSpeaker {
                log.warning(
                    """
                    AudioSession didChangeRoute with speakerOn:\(session.currentRoute.isSpeaker)
                    while CallSettings have speakerOn:\(activeCallSettings.speakerOn).
                    We will update CallSettings to match the AudioSession's
                    current configuration
                    """,
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

    /// Updates the audio session configuration based on the provided call
    /// settings and own capabilities.
    ///
    /// - Parameters:
    ///   - callSettings: The current call settings.
    ///   - ownCapabilities: The set of the user's own audio capabilities.
    ///   - file: The file where this method is called.
    ///   - functionName: The name of the function where this method is called.
    ///   - line: The line number where this method is called.
    private func didUpdate(
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else {
                return
            }

            let configuration = policy.configuration(
                for: callSettings,
                ownCapabilities: ownCapabilities
            )

            guard configuration != lastUsedConfiguration else {
                return
            }

            log.debug(
                """
                Will configure AudioSession with
                - configuration: \(configuration)
                - policy: \(type(of: policy)) 
                - settings: \(callSettings) 
                - ownCapabilities:\(ownCapabilities)
                """,
                subsystems: .audioSession,
                functionName: functionName,
                fileName: file,
                lineNumber: line
            )

            if configuration.category == .playback, isRecording {
                log.debug(
                    "AudioSession is currently recording. Defer execution until recording has stopped.",
                    subsystems: .audioSession,
                    functionName: functionName,
                    fileName: file,
                    lineNumber: line
                )
                await deferExecutionUntilRecordingIsStopped()
            }

            if
                configuration.overrideOutputAudioPort == nil,
                audioSession.category == AVAudioSession.Category.playAndRecord
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
                    "Failed while setting AudioSession category:\(configuration.category) mode:\(configuration.mode) options:\(configuration.options)",
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

            lastUsedConfiguration = configuration
        }
    }

    /// Defers execution until recording is stopped.
    private func deferExecutionUntilRecordingIsStopped() async {
        do {
            _ = try await $isRecording
                .filter { $0 == false }
                .nextValue(timeout: deferExecutionDueToRecordingInterval)
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

extension StreamAudioSession: Encodable {
    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case isActive
        case isRecording
        case isAudioModuleRecording
        case isAudioModulePlaying
        case category
        case mode
        case overrideOutputPort
        case useManualAudio
        case isAudioEnabled
        case hasRecordPermission
        case speakerOn
        case device
        case deviceIsExternal = "device.isExternal"
        case deviceIsSpeaker = "device.isSpeaker"
        case deviceIsReceiver = "device.isReceiver"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(audioSession.isActive, forKey: .isActive)
        try container.encode(isRecording, forKey: .isRecording)
        try container.encode(audioDeviceModule.recording, forKey: .isAudioModuleRecording)
        try container.encode(audioDeviceModule.playing, forKey: .isAudioModulePlaying)
        try container.encode(audioSession.category.rawValue, forKey: .category)
        try container.encode(audioSession.mode.rawValue, forKey: .mode)
        try container.encode(audioSession.overrideOutputPort.stringValue, forKey: .overrideOutputPort)
        try container.encode(audioSession.hasRecordPermission, forKey: .hasRecordPermission)
        try container.encode("\(audioSession.currentRoute)", forKey: .device)
        try container.encode(audioSession.currentRoute.isExternal, forKey: .deviceIsExternal)
        try container.encode(audioSession.currentRoute.isSpeaker, forKey: .deviceIsSpeaker)
        try container.encode(audioSession.currentRoute.isReceiver, forKey: .deviceIsReceiver)

        if let rtcAudioSession = audioSession as? StreamRTCAudioSession {
            try container.encode(rtcAudioSession.useManualAudio, forKey: .useManualAudio)
            try container.encode(rtcAudioSession.isAudioEnabled, forKey: .isAudioEnabled)
        }
    }
}

/// A key for dependency injection of an `AudioSessionProtocol` instance
/// that represents the active call audio session.
extension StreamAudioSession: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamAudioSession?
}

extension InjectedValues {
    /// The active call's audio session. The value is being set on
    /// `StreamAudioSession` `init` / `deinit`
    var activeCallAudioSession: StreamAudioSession? {
        get {
            Self[StreamAudioSession.self]
        }
        set {
            Self[StreamAudioSession.self] = newValue
        }
    }
}
