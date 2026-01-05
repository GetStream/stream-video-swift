//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserInfoResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]
    public var id: String
    public var image: String
    public var name: String
    public var roles: [String]

    public init(custom: [String: RawJSON], id: String, image: String, name: String, roles: [String]) {
        self.custom = custom
        self.id = id
        self.image = image
        self.name = name
        self.roles = roles
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case id
        case image
        case name
        case roles
    }
    
    public static func == (lhs: UserInfoResponse, rhs: UserInfoResponse) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.name == rhs.name &&
            lhs.roles == rhs.roles
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(name)
        hasher.combine(roles)
    }
}
