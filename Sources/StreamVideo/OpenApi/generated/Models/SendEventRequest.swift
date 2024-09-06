//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct SendEventRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]?

    public init(custom: [String: RawJSON]? = nil) {
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
    }
}
