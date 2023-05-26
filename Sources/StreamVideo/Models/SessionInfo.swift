//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents information about a session.
public struct SessionInfo: Sendable {
    /// The call data associated with the session.
    public var call: CallData
    /// The unique identifier for the call.
    public var callCid: String
    /// The date and time when the session was created.
    public var createdAt: Date
    /// The unique identifier for the session.
    public var sessionId: String
}
