//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SendReactionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var reaction: ReactionResponse

    public init(duration: String, reaction: ReactionResponse) {
        self.duration = duration
        self.reaction = reaction
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case reaction
    }
    
    public static func == (lhs: SendReactionResponse, rhs: SendReactionResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.reaction == rhs.reaction
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(reaction)
    }
}
