//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct TypingIndicators: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool? = nil

    public init(enabled: Bool? = nil) {
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }
}
