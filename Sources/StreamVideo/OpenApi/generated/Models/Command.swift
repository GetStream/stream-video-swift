//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Command: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var args: String
    public var createdAt: Date? = nil
    public var description: String
    public var name: String
    public var set: String
    public var updatedAt: Date? = nil

    public init(args: String, createdAt: Date? = nil, description: String, name: String, set: String, updatedAt: Date? = nil) {
        self.args = args
        self.createdAt = createdAt
        self.description = description
        self.name = name
        self.set = set
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case args
        case createdAt = "created_at"
        case description
        case name
        case set
        case updatedAt = "updated_at"
    }
}
