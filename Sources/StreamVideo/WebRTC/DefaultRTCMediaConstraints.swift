//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCMediaConstraints {
    
    static let defaultConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
    )
    
    static let iceRestartConstraints = RTCMediaConstraints(
        mandatoryConstraints: [kRTCMediaConstraintsIceRestart: kRTCMediaConstraintsValueTrue],
        optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
    )
}
