//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCSdpType: CustomStringConvertible {
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
