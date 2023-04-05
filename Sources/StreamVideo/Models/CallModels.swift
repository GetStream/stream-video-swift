//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import SwiftUI


/// Provides info about the call.
public struct CallInfo: Sendable {
    /// The call cId, consisting of the call type and id.
    public let cId: String
    /// Whether the call is in backstage.
    public let backstage: Bool
    /// Array of blocked users.
    public var blockedUsers: [User]
}

/// Represents a participant event during a call.
public struct ParticipantEvent: Sendable {
    public let id: String
    public let action: ParticipantAction
    public let user: String
    public let imageURL: URL?
}

/// Represents a participant action (joining / leaving a call).
public enum ParticipantAction: Sendable {
    case join
    case leave
    
    public var display: String {
        switch self {
        case .leave:
            return "left"
        case .join:
            return "joined"
        }
    }
}

public enum RecordingState {
    case noRecording
    case requested
    case recording
}
