//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

extension RTCMediaConstraints {
    
    static let defaultConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
    )
}
