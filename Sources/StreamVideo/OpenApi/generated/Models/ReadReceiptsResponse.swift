//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class ReadReceiptsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }
    
    public static func == (lhs: ReadReceiptsResponse, rhs: ReadReceiptsResponse) -> Bool {
        lhs.enabled == rhs.enabled
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
    }
}