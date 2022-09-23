//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct IncomingCall: Identifiable, Sendable, Equatable {
    
    public static func == (lhs: IncomingCall, rhs: IncomingCall) -> Bool {
        lhs.id == rhs.id
    }
    
    public let id: String
    public let callerId: String
    public let type: String
    public let participants: [CallParticipant]
    
    public init(
        id: String,
        callerId: String,
        type: String,
        participants: [CallParticipant]
    ) {
        self.id = id
        self.callerId = callerId
        self.type = type
        self.participants = participants
    }
}
