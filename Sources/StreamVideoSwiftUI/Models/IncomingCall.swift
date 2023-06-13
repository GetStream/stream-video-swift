//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    public let participants: [Member]
    public let timeout: TimeInterval
}
