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
}
