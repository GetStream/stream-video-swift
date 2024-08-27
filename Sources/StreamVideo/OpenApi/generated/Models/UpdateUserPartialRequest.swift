//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateUserPartialRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var id: String
    public var set: [String: RawJSON]? = nil
    public var unset: [String]? = nil

    public init(id: String, set: [String: RawJSON]? = nil, unset: [String]? = nil) {
        self.id = id
        self.set = set
        self.unset = unset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case set
        case unset
    }
}
