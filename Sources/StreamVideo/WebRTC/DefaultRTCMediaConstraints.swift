//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCMediaConstraints: @unchecked Sendable {

    fileprivate enum Key: String {
        case DtlsSrtpKeyAgreement
        case kRTCMediaConstraintsIceRestart
        case echoCancellation
        case googEchoCancellation
        case googAutoGainControl
        case googNoiseSuppression
        case googHighpassFilter
        case googTypingNoiseDetection
    }

    fileprivate enum Constraint {
        case activated(Key)
        case deactivated(Key)

        var key: String {
            switch self {
            case let .activated(key):
                return key.rawValue
            case let .deactivated(key):
                return key.rawValue
            }
        }

        var value: String {
            switch self {
            case .activated:
                return kRTCMediaConstraintsValueTrue
            case .deactivated:
                return kRTCMediaConstraintsValueFalse
            }
        }
    }

    fileprivate convenience init(
        mandatory: [Constraint]? = nil,
        optional: [Constraint]? = nil
    ) {
        self.init(
            mandatoryConstraints: mandatory?.rawValue,
            optionalConstraints: optional?.rawValue
        )
    }
}

extension Array where Element == RTCMediaConstraints.Constraint {

    fileprivate var rawValue: [String: String] {
        reduce([String: String]()) { partialResult, constraint in
            var partialResult = partialResult
            partialResult[constraint.key] = constraint.value
            return partialResult
        }
    }
}

extension RTCMediaConstraints {
    nonisolated(unsafe) static let defaultConstraints = RTCMediaConstraints(
        optional: [.activated(.DtlsSrtpKeyAgreement)]
    )

    nonisolated(unsafe) static let iceRestartConstraints = RTCMediaConstraints(
        mandatory: [.activated(.kRTCMediaConstraintsIceRestart)],
        optional: [.activated(.DtlsSrtpKeyAgreement)]
    )

    /// Media constraints optimized for High-Fidelity (HiFi) audio capture.
    ///
    /// These constraints disable all audio processing features to preserve
    /// the original audio quality, making them ideal for music streaming
    /// and high-quality voice calls where audio fidelity is paramount.
    ///
    /// The following audio processing features are explicitly disabled:
    /// - Echo cancellation (both standard and Google's implementation)
    /// - Automatic gain control
    /// - Noise suppression
    /// - Highpass filtering
    /// - Typing noise detection
    ///
    /// - Warning: Disabling echo cancellation may cause audio feedback when
    ///   using speakers. Users should use headphones or ensure proper
    ///   acoustic isolation when HiFi mode is enabled.
    ///
    /// - Note: DTLS-SRTP key agreement remains enabled for secure audio
    ///   transmission.
    nonisolated(unsafe) static let hiFiAudioConstraints = RTCMediaConstraints(
        optional: [
            .activated(.DtlsSrtpKeyAgreement),
            .deactivated(.echoCancellation),
            .deactivated(.googEchoCancellation),
            .deactivated(.googAutoGainControl),
            .deactivated(.googNoiseSuppression),
            .deactivated(.googHighpassFilter),
            .deactivated(.googTypingNoiseDetection)
        ]
    )
}
