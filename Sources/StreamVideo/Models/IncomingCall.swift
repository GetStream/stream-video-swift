//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents an incoming call.
public struct IncomingCall: Identifiable, Sendable, Equatable {
    
    public static func == (lhs: IncomingCall, rhs: IncomingCall) -> Bool {
        lhs.id == rhs.id
    }
    
    public let id: String
    public let callerId: String
    public let type: CallType
    public let participants: [CallParticipant]
    
    public init(
        id: String,
        callerId: String,
        type: String,
        participants: [CallParticipant]
    ) {
        self.id = id
        self.callerId = callerId
        self.type = CallType(name: type)
        self.participants = participants
    }
}
