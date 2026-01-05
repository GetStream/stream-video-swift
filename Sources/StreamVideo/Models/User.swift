//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Model for the user's info.
public struct User: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let imageURL: URL?
    public let role: String
    public let type: UserAuthType
    public let customData: [String: RawJSON]

    /// User's name that was provided when the object was created. It will be used when communicating
    /// with the API and in cases where it doesn't make sense to override `nil` values with the
    /// `non-nil` id.
    public let originalName: String?

    /// A computed property that can be used for UI elements where you need to display user's identifier.
    /// If a `name` value was provided on initialisation it will return it. Otherwise returns the `id`.
    public var name: String { originalName ?? id }

    public init(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        role: String = "user",
        customData: [String: RawJSON] = [:]
    ) {
        self.init(
            id: id,
            name: name,
            imageURL: imageURL,
            role: role,
            type: .regular,
            customData: customData
        )
    }

    init(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        role: String = "user",
        type: UserAuthType = .regular,
        customData: [String: RawJSON] = [:]
    ) {
        self.id = id
        originalName = name
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
            blockedUserIds: [],
            createdAt: Date(),
            custom: [:],
            id: id,
            language: Locale.current.languageCode ?? "en",
            role: "user",
            teams: [],
            updatedAt: Date()
        )
    }
}

public enum UserAuthType: Sendable, Codable, Hashable {
    case regular
    case anonymous
    case guest
}
