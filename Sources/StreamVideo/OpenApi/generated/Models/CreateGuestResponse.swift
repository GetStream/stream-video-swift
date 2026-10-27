//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CreateGuestResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// the access token to authenticate the user
    public var accessToken: String
    /// Duration of the request in milliseconds
    public var duration: String
    /// User response object
    public var user: UserResponse

    public init(accessToken: String, duration: String, user: UserResponse) {
        self.accessToken = accessToken
        self.duration = duration
        self.user = user
    }

    public enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case duration
        case user
    }
}

extension CreateGuestResponse: Hashable {
    public static func == (lhs: CreateGuestResponse, rhs: CreateGuestResponse) -> Bool {
        lhs.accessToken == rhs.accessToken &&
            lhs.duration == rhs.duration &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
        hasher.combine(duration)
        hasher.combine(user)
    }
}
