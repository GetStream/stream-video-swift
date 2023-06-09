//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a member in the call.
public struct Member: Identifiable, Equatable, Sendable, Codable {
    /// The member's id.
    public var id: String {
        user.id
    }
    /// The underlying user.
    public let user: User
    /// The role of the member in the call.
    public let role: String
    /// Custom data of the member in the call.
    public let customData: [String: RawJSON]
    
    public init(user: User, role: String? = nil, customData: [String : RawJSON] = [:]) {
        self.user = user
        self.role = role ?? user.role
        self.customData = customData
    }
}
