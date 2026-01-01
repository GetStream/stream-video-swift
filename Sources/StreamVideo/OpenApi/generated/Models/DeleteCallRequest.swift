//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class DeleteCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var hard: Bool?

    public init(hard: Bool? = nil) {
        self.hard = hard
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hard
    }
    
    public static func == (lhs: DeleteCallRequest, rhs: DeleteCallRequest) -> Bool {
        lhs.hard == rhs.hard
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hard)
    }
}
