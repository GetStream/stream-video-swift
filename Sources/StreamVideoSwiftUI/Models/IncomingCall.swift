//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

/// Represents an incoming call.
public struct IncomingCall: Identifiable, Sendable, Equatable {

    public static func == (lhs: IncomingCall, rhs: IncomingCall) -> Bool {
        lhs.id == rhs.id
    }
    
    public let id: String
    public let caller: User
    public let type: String
    public let members: [Member]
    public let timeout: TimeInterval

    public init(
        id: String,
        caller: User,
        type: String,
        members: [Member],
        timeout: TimeInterval
    ) {
        self.id = id
        self.caller = caller
        self.type = type
        self.members = members
        self.timeout = timeout
    }
}
