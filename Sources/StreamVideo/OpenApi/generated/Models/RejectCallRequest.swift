//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct RejectCallRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var reason: String? = nil

    public init(reason: String? = nil) {
        self.reason = reason
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
    }
}
