//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCSignalingState: CustomStringConvertible {
    /// A textual representation of the signaling state.
    ///
    /// - Returns: A string describing the signaling state:
    ///   - "stable": No offer/answer exchange in progress
    ///   - "haveLocalOffer": Local offer, waiting for answer
    ///   - "haveLocalPrAnswer": Local provisional answer, waiting for final
    ///   - "haveRemoteOffer": Received offer, haven't sent answer
    ///   - "haveRemotePrAnswer": Received provisional answer, waiting for final
    ///   - "closed": The peer connection is closed
    ///   - "unknown/default": For any future, undefined states
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
