//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides information about the connection quality of participants.
public enum ConnectionQuality: Equatable, Sendable {
    case unknown
    case poor
    case good
    case excellent
}

extension Stream_Video_Sfu_Models_ConnectionQuality {

    var mapped: ConnectionQuality {
        switch self {
        case .poor:
            return .poor
        case .good:
            return .good
        case .excellent:
            return .excellent
        default:
            return .unknown
        }
    }
}
