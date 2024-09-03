//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BlockListOptions: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum Behavior: String, Codable, CaseIterable {
        case block
        case flag
        case shadowBlock = "shadow_block"
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public var behavior: Behavior
    public var blocklist: String

    public init(behavior: Behavior, blocklist: String) {
        self.behavior = behavior
        self.blocklist = blocklist
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case behavior
        case blocklist
    }
}
