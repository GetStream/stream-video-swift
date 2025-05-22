//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides information about the connection quality of participants.
public enum ConnectionQuality: Hashable, Sendable {
    case unknown
    case poor
    case good
    case excellent
}

extension Stream_Video_Sfu_Models_ConnectionQuality {

    var mapped: ConnectionQuality {
        switch self {
        case .poor:
            .poor
        case .good:
            .good
        case .excellent:
            .excellent
        default:
            .unknown
        }
    }
}
