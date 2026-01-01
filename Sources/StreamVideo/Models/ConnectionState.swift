//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

public enum ConnectionState: Equatable, Sendable {
    case disconnected(reason: DisconnectionReason? = nil)
    case connecting
    case reconnecting
    case connected
}

public enum DisconnectionReason: Equatable, Sendable {
    
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

public enum ReconnectionStatus: Sendable {
    case connected
    case reconnecting
    case migrating
    case disconnected
}
