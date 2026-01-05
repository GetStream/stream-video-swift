//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CreateGuestRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var user: UserRequest

    public init(user: UserRequest) {
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
    }
    
    public static func == (lhs: CreateGuestRequest, rhs: CreateGuestRequest) -> Bool {
        lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
