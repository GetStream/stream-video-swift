//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct DeleteCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var hard: Bool?

    public init(hard: Bool? = nil) {
        self.hard = hard
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hard
    }
}
