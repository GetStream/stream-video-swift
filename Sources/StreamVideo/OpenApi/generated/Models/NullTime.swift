//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct NullTime: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var hasValue: Bool? = nil
    public var value: Date? = nil

    public init(hasValue: Bool? = nil, value: Date? = nil) {
        self.hasValue = hasValue
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hasValue = "HasValue"
        case value = "Value"
    }
}
