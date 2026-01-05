//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCSignalingState {
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
            return "have-local-offer"
        case .haveLocalPrAnswer:
            return "have-local-pr-answer"
        case .haveRemoteOffer:
            return "have-remote-offer"
        case .haveRemotePrAnswer:
            return "have-remote-pr-answer"
        case .closed:
            return "closed"
        @unknown default:
            return "unknown/default"
        }
    }
}
