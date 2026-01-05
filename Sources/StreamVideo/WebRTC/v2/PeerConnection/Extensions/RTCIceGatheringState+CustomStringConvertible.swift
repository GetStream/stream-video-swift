//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extension to make RTCIceGatheringState conform to CustomStringConvertible.
extension RTCIceGatheringState {

    /// A textual representation of the ICE gathering state.
    public var description: String {
        switch self {
        case .new:
            return "new"
        case .gathering:
            return "gathering"
        case .complete:
            return "complete"
        @unknown default:
            return "unknown/default"
        }
    }
}
