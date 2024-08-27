//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ReadReceipts: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }
}
