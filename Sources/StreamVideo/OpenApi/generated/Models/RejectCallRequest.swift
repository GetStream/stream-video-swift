//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RejectCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var reason: String?

    public init(reason: String? = nil) {
        self.reason = reason
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
    }
    
    public static func == (lhs: RejectCallRequest, rhs: RejectCallRequest) -> Bool {
        lhs.reason == rhs.reason
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(reason)
    }
}
