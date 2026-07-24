//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

/// Represents a call event.
public enum CallEvent: Sendable {
    /// Incoming call.
    case incoming(IncomingCall)
    /// An outgoing call is accepted.
    case accepted(CallEventInfo)
    /// An outgoing call is rejected.
    case rejected(CallEventInfo)
    /// The call is ended.
    case ended(CallEventInfo)
    /// A user was blocked.
    case userBlocked(CallEventInfo)
    /// A user was unblocked.
    case userUnblocked(CallEventInfo)
    /// Session started.
    case sessionStarted(CallSessionResponse)
}

public enum CallEventAction: Sendable {
    case accept
    case reject
    case cancel
    case end
    case block
    case unblock
}

/// Contains info about a call event.
public struct CallEventInfo: Event, Sendable {
    public let callCid: String
    public let user: User?
    public let action: CallEventAction
    
    public var callId: String {
        let components = callCid.components(separatedBy: ":")
        if components.count > 1 {
            return components[1]
        } else {
            return ""
        }
    }
    
    public var type: String {
        callCid.components(separatedBy: ":").first ?? "default"
    }
}
