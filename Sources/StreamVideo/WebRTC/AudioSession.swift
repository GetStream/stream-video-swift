//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

protocol AudioSessionDelegate: AnyObject {

    func audioSessionDidUpdateCallSettings(
        _ audioSession: AudioSession,
        callSettings: CallSettings
    )
}

/// The `AudioSession` class manages the device's audio session for an application,
/// providing control over activation, mode configuration, and routing to speakers or in-ear speakers.
final class AudioSession: NSObject, RTCAudioSessionDelegate, @unchecked Sendable {
    private enum SpeakerAction {
        case routeUpdate(AVAudioSessionRouteDescription, CallSettings)
        case respectCallSettings(AVAudioSessionRouteDescription, CallSettings)
    }

    private let audioSession = RTCAudioSession.sharedInstance()
    private let processingQueue = DispatchQueue(label: "io.getstream.audiosession", target: .global(qos: .userInteractive))
    @Atomic private var activeCallSettings: CallSettings?

    weak var delegate: AudioSessionDelegate?

    override init() {
        super.init()
        audioSession.add(self)
        audioSession.useManualAudio = true
        audioSession.isAudioEnabled = true

        let configuration = RTCAudioSessionConfiguration.default
        performAudioSessionOperation {
            try $0.setConfiguration(.default)
            log
                .debug(
                    "AudioSession updated configuration with category: \(configuration.category) options: \(configuration.categoryOptions) mode: \(configuration.mode)"
                )
        }
    }

    // MARK: - CallSettings

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) {
        guard settings != activeCallSettings else { return }

        performSessionAction(settings.audioOutputOn)
        performSpeakerUpdateAction(
            .respectCallSettings(
                audioSession.currentRoute,
                settings
            )
        )
        activeCallSettings = settings

        log.debug(
            "AudioSession updated isActive:\(settings.audioOutputOn) speakerOn:\(settings.speakerOn).",
            subsystems: .webRTC
        )
    }

    // MARK: - RTCAudioSessionDelegate

    func audioSessionDidChangeRoute(
        _ session: RTCAudioSession,
        reason: AVAudioSession.RouteChangeReason,
        previousRoute: AVAudioSessionRouteDescription
    ) {
        guard let activeCallSettings else {
            return
        }
        let currentRoute = session.currentRoute

        switch reason {
        case .unknown:
            performSpeakerUpdateAction(.routeUpdate(currentRoute, activeCallSettings))
        case .newDeviceAvailable:
            performSpeakerUpdateAction(.routeUpdate(currentRoute, activeCallSettings))
        case .oldDeviceUnavailable:
            performSpeakerUpdateAction(.respectCallSettings(currentRoute, activeCallSettings))
        case .categoryChange:
            performSpeakerUpdateAction(.respectCallSettings(currentRoute, activeCallSettings))
        case .override:
            performSpeakerUpdateAction(.routeUpdate(currentRoute, activeCallSettings))
        case .wakeFromSleep:
            performSpeakerUpdateAction(.respectCallSettings(currentRoute, activeCallSettings))
        case .noSuitableRouteForCategory:
            performSpeakerUpdateAction(.routeUpdate(currentRoute, activeCallSettings))
        case .routeConfigurationChange:
            performSpeakerUpdateAction(.respectCallSettings(currentRoute, activeCallSettings))
        @unknown default:
            performSpeakerUpdateAction(.routeUpdate(currentRoute, activeCallSettings))
        }
    }

    func audioSession(
        _ session: RTCAudioSession,
        didChangeCanPlayOrRecord canPlayOrRecord: Bool
    ) { log.info("AudioSession can playOrRecord:\(canPlayOrRecord).") }

    func audioSessionDidStopPlayOrRecord(
        _ session: RTCAudioSession
    ) { log.info("AudioSession cannot playOrRecord.") }

    func audioSession(
        _ audioSession: RTCAudioSession,
        didSetActive active: Bool
    ) {
        guard let activeCallSettings else { return }
        performSessionAction(active)
        performSpeakerUpdateAction(
            .respectCallSettings(
                audioSession.currentRoute,
                activeCallSettings
            )
        )
    }

    func audioSession(
        _ audioSession: RTCAudioSession,
        failedToSetActive active: Bool,
        error: any Error
    ) {
        log.error(
            "AudioSession failedToSetActive active:\(active)",
            error: error
        )
        performSessionAction(false)
    }

    func audioSession(
        _ audioSession: RTCAudioSession,
        audioUnitStartFailedWithError error: any Error
    ) {
        log.error(
            "AudioSession audioUnitStartFailedWithError",
            error: error
        )
        performSessionAction(false)
    }

    // MARK: - Private helpers

    private func performAudioSessionOperation(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        _ operation: @escaping (RTCAudioSession) throws -> Void
    ) {
        processingQueue.async { [weak self] in
            guard let audioSession = self?.audioSession else { return }
            audioSession.lockForConfiguration()
            do {
                try operation(audioSession)
            } catch {
                log.error(
                    error,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            }
            audioSession.unlockForConfiguration()
        }
    }

    private func performSpeakerUpdateAction(_ action: SpeakerAction) {
        switch action {
        case let .routeUpdate(currentRoute, currentCallSettings):
            let updatedCallSettings = currentCallSettings
                .withUpdatedSpeakerState(currentRoute.isSpeaker)

            guard currentCallSettings != updatedCallSettings else {
                return
            }

            delegate?.audioSessionDidUpdateCallSettings(
                self,
                callSettings: updatedCallSettings
            )
            log.debug(
                "AudioSession route requires speaker update \(currentCallSettings.speakerOn) → \(updatedCallSettings.speakerOn)."
            )

        case let .respectCallSettings(currentRoute, currentCallSettings):
            if currentRoute.isSpeaker != currentCallSettings.speakerOn {
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

                performAudioSessionOperation {
                    try $0.setMode(mode.rawValue)
                    try $0.setCategory(category, with: categoryOptions)
                    try $0.overrideOutputAudioPort(overrideOutputAudioPort)

                    log.debug(
                        """
                        AudioSession updated mode:\(mode
                            .rawValue) category:\(category)  options:\(categoryOptions) overrideOutputAudioPort:\(overrideOutputAudioPort ==
                            .speaker ? ".speaker" : ".none")
                        """
                    )
                }
            }
        }
    }

    private func performSessionAction(_ isActive: Bool) {
        guard audioSession.isActive != isActive else {
            return
        }
        log.debug("AudioSession will attempt to set isActive:\(isActive).")
        performAudioSessionOperation { try $0.setActive(isActive) }
    }
}

extension AVAudioSessionRouteDescription {

    override open var description: String {
        """
        AudioSessionRouter 
        isExternal:\(isExternal)
        Input name:\(inputs.map(\.portName).joined(separator: ",")) type:\(inputs.map(\.portType.rawValue).joined(separator: ","))
        Output name:\(outputs.map(\.portName).joined(separator: ",")) type:\(outputs.map(\.portType.rawValue)
            .joined(separator: ","))
        """
    }

    private static let externalPorts: Set<AVAudioSession.Port> = [
        .bluetoothA2DP, .bluetoothLE, .bluetoothHFP, .carAudio, .headphones
    ]

    var isExternal: Bool {
        outputs.map(\.portType).contains { Self.externalPorts.contains($0) }
    }

    var isSpeaker: Bool {
        outputs.map(\.portType).contains { $0 == .builtInSpeaker }
    }

    var isReceiver: Bool {
        outputs.map(\.portType).contains { $0 == .builtInReceiver }
    }

    var outputTypes: String {
        outputs
            .map(\.portType.rawValue)
            .joined(separator: ",")
    }
}

extension AVAudioSession.RouteChangeReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return ".unknown"
        case .newDeviceAvailable:
            return ".newDeviceAvailable"
        case .oldDeviceUnavailable:
            return ".oldDeviceUnavailable"
        case .categoryChange:
            return ".categoryChange"
        case .override:
            return ".override"
        case .wakeFromSleep:
            return ".wakeFromSleep"
        case .noSuitableRouteForCategory:
            return ".noSuitableRouteForCategory"
        case .routeConfigurationChange:
            return ".routeConfigurationChange"
        @unknown default:
            return "Unknown Reason"
        }
    }
}

extension AVAudioSession.CategoryOptions: CustomStringConvertible {
    public var description: String {
        var options: [String] = []

        if contains(.mixWithOthers) {
            options.append(".mixWithOthers")
        }
        if contains(.duckOthers) {
            options.append(".duckOthers")
        }
        if contains(.allowBluetooth) {
            options.append(".allowBluetooth")
        }
        if contains(.defaultToSpeaker) {
            options.append(".defaultToSpeaker")
        }
        if contains(.interruptSpokenAudioAndMixWithOthers) {
            options.append(".interruptSpokenAudioAndMixWithOthers")
        }
        if contains(.allowBluetoothA2DP) {
            options.append(".allowBluetoothA2DP")
        }
        if contains(.allowAirPlay) {
            options.append(".allowAirPlay")
        }
        if #available(iOS 14.5, *) {
            if contains(.overrideMutedMicrophoneInterruption) {
                options.append(".overrideMutedMicrophoneInterruption")
            }
        }

        return options.isEmpty ? ".noOptions" : options.joined(separator: ", ")
    }
}

extension AVAudioSessionPortDescription {
    override public var description: String {
        "<Port type:\(portType.rawValue) name:\(portName)>"
    }
}

extension RTCAudioSessionConfiguration {

    static let `default`: RTCAudioSessionConfiguration = {
        let configuration = RTCAudioSessionConfiguration.webRTC()
//        var categoryOptions: AVAudioSession.CategoryOptions = [
//            .allowBluetooth,
//            .allowBluetoothA2DP
//        ]
        configuration.mode = AVAudioSession.Mode.default.rawValue
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
//        configuration.categoryOptions = categoryOptions
        return configuration
    }()
}
