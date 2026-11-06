//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CreateGuestRequest: Sendable, Encodable, JSONEncodable {
    /// User request object
    public let user: UserRequest

    public init(user: UserRequest) {
        self.user = user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(user, forKey: .user)
    }
}

extension CreateGuestRequest: Hashable {
    public static func == (lhs: CreateGuestRequest, rhs: CreateGuestRequest) -> Bool {
        lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
