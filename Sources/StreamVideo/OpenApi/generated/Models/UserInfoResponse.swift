//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserInfoResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]
    public var image: String
    public var name: String
    public var roles: [String]

    public init(custom: [String: RawJSON], image: String, name: String, roles: [String]) {
        self.custom = custom
        self.image = image
        self.name = name
        self.roles = roles
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case image
        case name
        case roles
    }
}
