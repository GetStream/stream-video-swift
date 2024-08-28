//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCSignalingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .stable:
            return "stable"
        case .haveLocalOffer:
            return "haveLocalOffer"
        case .haveLocalPrAnswer:
            return "haveLocalPrAnswer"
        case .haveRemoteOffer:
            return "haveRemoteOffer"
        case .haveRemotePrAnswer:
            return "haveRemotePrAnswer"
        case .closed:
            return "closed"
        @unknown default:
            return "unknown/default"
        }
    }
}
