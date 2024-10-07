//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PrivacySettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var typingIndicators: TypingIndicators?

    public init(typingIndicators: TypingIndicators? = nil) {
        self.typingIndicators = typingIndicators
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case typingIndicators = "typing_indicators"
    }
    
    public static func == (lhs: PrivacySettings, rhs: PrivacySettings) -> Bool {
        lhs.typingIndicators == rhs.typingIndicators
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(typingIndicators)
    }
}
