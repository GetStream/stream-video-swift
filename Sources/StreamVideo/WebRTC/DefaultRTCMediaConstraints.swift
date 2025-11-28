//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCMediaConstraints {
    
    nonisolated(unsafe) static let defaultConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: [
            "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue,
            /// Added support for Google's media constraints to improve transmitted audio
            /// https://github.com/GetStream/react-native-webrtc/pull/20/commits/6476119456005dc35ba00e9bf4d4c4124c6066e8
            "googAutoGainControl": kRTCMediaConstraintsValueTrue,
            "googNoiseSuppression": kRTCMediaConstraintsValueTrue,
            "googEchoCancellation": kRTCMediaConstraintsValueTrue,
            "googHighpassFilter": kRTCMediaConstraintsValueTrue,
            "googTypingNoiseDetection": kRTCMediaConstraintsValueTrue,
            "googAudioMirroring": kRTCMediaConstraintsValueFalse
        ]
    )
    
    nonisolated(unsafe) static let iceRestartConstraints = RTCMediaConstraints(
        mandatoryConstraints: [kRTCMediaConstraintsIceRestart: kRTCMediaConstraintsValueTrue],
        optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
    )
}
