//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
}

enum CallEventAction: Sendable {
    case accept
    case reject
    case cancel
}

struct IncomingCallEvent: Event {
    let callCid: String
    let createdBy: String
    let type: String
    let users: [Stream_Video_User]
}

/// Contains info about a call event.
public struct CallEventInfo: Event, Sendable {
    let callId: String
    let senderId: String
    let action: CallEventAction
}
