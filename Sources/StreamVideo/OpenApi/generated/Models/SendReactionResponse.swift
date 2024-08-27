//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct SendReactionResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
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
}
