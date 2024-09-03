//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ChannelMute: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var channel: ChannelResponse? = nil
    public var createdAt: Date
    public var expires: Date? = nil
    public var updatedAt: Date
    public var user: UserObject? = nil

    public init(channel: ChannelResponse? = nil, createdAt: Date, expires: Date? = nil, updatedAt: Date, user: UserObject? = nil) {
        self.channel = channel
        self.createdAt = createdAt
        self.expires = expires
        self.updatedAt = updatedAt
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case expires
        case updatedAt = "updated_at"
        case user
    }
}
