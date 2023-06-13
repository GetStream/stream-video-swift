//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Model for the user's info.
public struct User: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let name: String
    public let imageURL: URL?
    public let role: String
    public let type: UserAuthType
    public let customData: [String: RawJSON]

    public init(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        role: String = "user",
        type: UserAuthType = .regular,
        customData: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.name = name ?? id
        self.imageURL = imageURL
        self.role = role
        self.type = type
        self.customData = customData
    }
}

public extension User {
    /// Creates a guest user with the provided id.
    /// - Parameter userId: the id of the user.
    /// - Returns: a guest `User`.
    static func guest(_ userId: String) -> User {
        User(id: userId, name: userId, type: .guest)
    }

    /// Creates an anonymous user.
    /// - Returns: an anonymous `User`.
    static var anonymous: User {
        User(id: "!anon", type: .anonymous)
    }
}

public extension UserResponse {
    
    static func make(from id: String) -> UserResponse {
        UserResponse(
            createdAt: Date(),
            custom: [:],
            id: id,
            role: "user",
            teams: [],
            updatedAt: Date()
        )
    }
    
}

public enum UserAuthType: Sendable, Codable {
    case regular
    case anonymous
    case guest
}
