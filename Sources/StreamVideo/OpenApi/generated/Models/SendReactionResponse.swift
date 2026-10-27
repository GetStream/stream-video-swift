//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Basic response information
public final class SendReactionResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    public var duration: String
    public var reaction: ReactionResponse

    public init(duration: String, reaction: ReactionResponse) {
        self.duration = duration
        self.reaction = reaction
    }

    public enum CodingKeys: String, CodingKey {
        case duration
        case reaction
    }
}

extension SendReactionResponse: Hashable {
    public static func == (lhs: SendReactionResponse, rhs: SendReactionResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.reaction == rhs.reaction
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(reaction)
    }
}
