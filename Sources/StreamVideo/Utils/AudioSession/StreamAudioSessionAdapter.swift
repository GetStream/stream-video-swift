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

    @Injected(\.callAudioRecorder) private var callAudioRecorder

    /// The shared audio session instance conforming to `AudioSessionProtocol`
    /// that manages WebRTC audio settings.
    private let audioSession: AudioSessionProtocol
    private let serialQueue = SerialActorQueue()

    /// The current active call settings, or `nil` if no active call is in session.
    @Atomic private(set) var activeCallSettings: CallSettings?

    private let canRecordSubject = PassthroughSubject<Bool, Never>()
    var canRecordPublisher: AnyPublisher<Bool, Never> { canRecordSubject.eraseToAnyPublisher() }

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
        StreamActiveCallAudioSessionKey.currentValue = self

        audioSession.add(self)
        audioSession.useManualAudio = true
        audioSession.isAudioEnabled = true

        let configuration = RTCAudioSessionConfiguration.default
        serialQueue.async {
            await audioSession.updateConfiguration(
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
    }

    deinit {
        if StreamActiveCallAudioSessionKey.currentValue === self {
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
        didUpdate(settings, oldValue: activeCallSettings)
        activeCallSettings = settings
    }

    func prepareForRecording() {
        guard let activeCallSettings, !activeCallSettings.audioOn else {
            return
        }

        let settings = activeCallSettings
            .withUpdatedAudioState(true)
        didUpdate(settings, oldValue: activeCallSettings)
        self.activeCallSettings = settings
    }

    func requestRecordPermission() async -> Bool {
        await audioSession.requestRecordPermission()
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

        case (false, true) where session.category == AVAudioSession.Category.playAndRecord.rawValue:
            delegate?.audioSessionAdapterDidUpdateCallSettings(
                self,
                callSettings: activeCallSettings.withUpdatedSpeakerState(true)
            )

        default:
            break
        }
    }

    // MARK: - Private helpers

    private func didUpdate(
        _ callSettings: CallSettings?,
        oldValue: CallSettings?,
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) {
        serialQueue.async { [weak self] in
            guard let self else {
                return
            }

            if callSettings?.audioOn == false, oldValue?.audioOn == true {
                log.debug(
                    "Will defer execution until recording has stopped.",
                    subsystems: .audioSession,
                    functionName: functionName,
                    fileName: file,
                    lineNumber: line
                )
                await deferExecutionUntilRecordingIsStopped()
            }

            let category: AVAudioSession.Category = callSettings?.audioOn == true || callSettings?
                .speakerOn == true || callSettings?.videoOn == true
                ? .playAndRecord
                : .playback

            let mode: AVAudioSession.Mode = category == .playAndRecord
                ? callSettings?.speakerOn == true ? .videoChat : .voiceChat
                : .default

            let categoryOptions: AVAudioSession.CategoryOptions = category == .playAndRecord
                ? .playAndRecord
                : .playback

            let overridePort: AVAudioSession.PortOverride? = category == .playAndRecord
                ? callSettings?.speakerOn == true ? .speaker : AVAudioSession.PortOverride.none
                : nil

            await audioSession.updateConfiguration(
                functionName: functionName,
                file: file,
                line: line
            ) { [weak self] in
                if overridePort == nil, $0.category == AVAudioSession.Category.playAndRecord.rawValue {
                    try $0.overrideOutputAudioPort(.none)
                }

                do {
                    try $0.setCategory(
                        category,
                        mode: mode,
                        with: categoryOptions
                    )
                    self?.canRecordSubject.send(category == .playAndRecord)
                } catch {
                    log.error(
                        "Failed while setting category:\(category) mode:\(mode) options:\(categoryOptions)",
                        subsystems: .audioSession,
                        error: error,
                        functionName: functionName,
                        fileName: file,
                        lineNumber: line
                    )
                }
                if let overridePort {
                    try $0.overrideOutputAudioPort(overridePort)
                }
            }

            log.debug(
                "AudioSession updated with callSettings: \(callSettings?.description ?? "nil")",
                subsystems: .audioSession,
                functionName: functionName,
                fileName: file,
                lineNumber: line
            )
        }
    }

    private func deferExecutionUntilRecordingIsStopped() async {
        do {
            _ = try await callAudioRecorder
                .isRecordingPublisher
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
