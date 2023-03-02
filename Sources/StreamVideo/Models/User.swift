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
    public let extraData: [String: RawJSON]

    public init(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        role: String = "user",
        extraData: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.name = name ?? id
        self.imageURL = imageURL
        self.role = role
        self.extraData = extraData
    }
}
