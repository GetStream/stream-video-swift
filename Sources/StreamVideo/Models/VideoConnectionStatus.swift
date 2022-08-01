//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import LiveKit

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

extension DisconnectReason {
    
    var mapped: DisconnectionReason {
        switch self {
        case .user:
            return .user
        case .networkError(let error):
            return .networkError(error)
        }
    }
    
}

extension ConnectionState {
    
    var mapped: VideoConnectionStatus {
        switch self {
        case .disconnected(reason: let reason):
            return .disconnected(reason: reason?.mapped)
        case .connected:
            return .connected
        case .reconnecting:
            return .reconnecting
        case .connecting:
            return .connecting
        }
    }
    
}
