//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type is designed to store the JWT and the user it is related to.
public struct UserToken: Codable, Equatable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Created a new `Token` instance.
    /// - Parameter value: The JWT string value. It must be in valid format and contain `user_id` in payload.
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }

    /// Creates a `Token` instance from the provided `rawValue` if it's valid.
    /// - Parameter rawValue: The token string in JWT format.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        try self.init(
            rawValue: container.decode(String.self)
        )
    }
}

extension ClientError {
    public class InvalidToken: ClientError, @unchecked Sendable {}
}

public extension UserToken {
    
    static let empty = UserToken(rawValue: "")
}
