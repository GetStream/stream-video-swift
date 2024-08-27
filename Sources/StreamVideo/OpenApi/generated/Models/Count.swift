//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Count: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var approximate: Bool
    public var value: Int

    public init(approximate: Bool, value: Int) {
        self.approximate = approximate
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case approximate
        case value
    }
}
