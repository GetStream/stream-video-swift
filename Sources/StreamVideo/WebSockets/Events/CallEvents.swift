//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a call event.
public enum CallEvent: Sendable {
    /// Incoming call.
    case incoming(IncomingCall)
    /// An outgoing call is accepted.
    case accepted(CallEventInfo)
    /// An outgoing call is rejected.
    case rejected(CallEventInfo)
    /// An outgoing call is canceled.
    case canceled(CallEventInfo)
    /// The call is ended.
    case ended(CallEventInfo)
    /// A user was blocked.
    case userBlocked(CallEventInfo)
    /// A user was unblocked.
    case userUnblocked(CallEventInfo)
}

enum CallEventAction: Sendable {
    case accept
    case reject
    case cancel
    case end
    case block
    case unblock
}

struct IncomingCallEvent: Event {
    let callCid: String
    let createdBy: String
    let type: String
    let users: [User]
}

/// Contains info about a call event.
public struct CallEventInfo: Event, Sendable {
    let callId: String
    let user: User
    let action: CallEventAction
}
