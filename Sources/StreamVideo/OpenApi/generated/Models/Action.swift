//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Action: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var name: String
    public var style: String? = nil
    public var text: String
    public var type: String
    public var value: String? = nil

    public init(name: String, style: String? = nil, text: String, type: String, value: String? = nil) {
        self.name = name
        self.style = style
        self.text = text
        self.type = type
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case style
        case text
        case type
        case value
    }
}
