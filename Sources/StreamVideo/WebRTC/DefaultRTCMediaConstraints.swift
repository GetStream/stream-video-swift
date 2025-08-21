//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCMediaConstraints {

nonisolated(unsafe) static let defaultConstraints = RTCMediaConstraints(
    mandatoryConstraints: nil,
    optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
)

nonisolated(unsafe) static let iceRestartConstraints = RTCMediaConstraints(
    mandatoryConstraints: [kRTCMediaConstraintsIceRestart: kRTCMediaConstraintsValueTrue],
    optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
)

nonisolated(unsafe) static let hiFiAudioConstraints = RTCMediaConstraints(
    mandatoryConstraints: nil,
    optionalConstraints: [
        "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue,
        "echoCancellation": kRTCMediaConstraintsValueFalse,
        "googEchoCancellation": kRTCMediaConstraintsValueFalse,
        "googAutoGainControl": kRTCMediaConstraintsValueFalse,
        "googNoiseSuppression": kRTCMediaConstraintsValueFalse,
        "googHighpassFilter": kRTCMediaConstraintsValueFalse,
        "googTypingNoiseDetection": kRTCMediaConstraintsValueFalse
    ]
)
}
