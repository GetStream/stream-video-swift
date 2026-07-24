//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    public let video: Bool
    public let custom: [String: RawJSON]

    public init(
        id: String,
        caller: User,
        type: String,
        members: [Member],
        timeout: TimeInterval,
        video: Bool = false,
        custom: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.caller = caller
        self.type = type
        self.members = members
        self.timeout = timeout
        self.video = video
        self.custom = custom
    }
}
