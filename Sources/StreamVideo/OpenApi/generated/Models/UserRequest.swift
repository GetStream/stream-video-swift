//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// User request object
public final class UserRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Custom user data
    public var custom: [String: RawJSON]?
    /// User ID
    public var id: String
    /// User's profile image URL
    public var image: String?
    public var invisible: Bool?
    public var language: String?
    /// Optional name of user
    public var name: String?

    public init(
        custom: [String: RawJSON]? = nil,
        id: String,
        image: String? = nil,
        invisible: Bool? = nil,
        language: String? = nil,
        name: String? = nil
    ) {
        self.custom = custom
        self.id = id
        self.image = image
        self.invisible = invisible
        self.language = language
        self.name = name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(invisible, forKey: .invisible)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(name, forKey: .name)
    }
}

extension UserRequest: Hashable {
    public static func == (lhs: UserRequest, rhs: UserRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.invisible == rhs.invisible &&
            lhs.language == rhs.language &&
            lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(invisible)
        hasher.combine(language)
        hasher.combine(name)
    }
}
