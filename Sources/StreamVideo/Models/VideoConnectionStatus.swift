//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

public enum VideoConnectionStatus: Equatable {
    case disconnected(reason: DisconnectionReason? = nil)
    case connecting
    case reconnecting
    case connected
}

public enum DisconnectionReason: Equatable {
    
    public static func == (lhs: DisconnectionReason, rhs: DisconnectionReason) -> Bool {
        switch (lhs, rhs) {
        case (.user, .user):
            return true
        case (.networkError(_), .networkError(_)):
            return true
        default:
            return false
        }
    }
    
    case user // User initiated
    case networkError(_ error: Error)
}
