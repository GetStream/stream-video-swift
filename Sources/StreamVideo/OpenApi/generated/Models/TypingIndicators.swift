//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class TypingIndicators: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool?

    public init(enabled: Bool? = nil) {
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }
    
    public static func == (lhs: TypingIndicators, rhs: TypingIndicators) -> Bool {
        lhs.enabled == rhs.enabled
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
    }
}
