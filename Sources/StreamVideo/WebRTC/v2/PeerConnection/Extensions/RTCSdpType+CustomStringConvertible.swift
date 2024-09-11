//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCSdpType: CustomStringConvertible {
    /// A textual representation of the SDP type.
    ///
    /// - Returns: A string describing the SDP type:
    ///   - "offer" for an offer
    ///   - "prAnswer" for a provisional answer
    ///   - "answer" for a final answer
    ///   - "rollback" for a rollback operation
    ///   - "unknown/default" for any future, undefined types
    public var description: String {
        switch self {
        case .offer:
            return "offer"
        case .prAnswer:
            return "prAnswer"
        case .answer:
            return "answer"
        case .rollback:
            return "rollback"
        @unknown default:
            return "unknown/default"
        }
    }
}
