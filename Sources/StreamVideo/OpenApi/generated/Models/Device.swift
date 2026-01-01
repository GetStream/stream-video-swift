//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Device: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var disabled: Bool?
    public var disabledReason: String?
    public var id: String
    public var pushProvider: String
    public var pushProviderName: String?
    public var userId: String
    public var voip: Bool?

    public init(
        createdAt: Date,
        disabled: Bool? = nil,
        disabledReason: String? = nil,
        id: String,
        pushProvider: String,
        pushProviderName: String? = nil,
        userId: String,
        voip: Bool? = nil
    ) {
        self.createdAt = createdAt
        self.disabled = disabled
        self.disabledReason = disabledReason
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.userId = userId
        self.voip = voip
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case disabled
        case disabledReason = "disabled_reason"
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case userId = "user_id"
        case voip
    }
    
    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.disabled == rhs.disabled &&
            lhs.disabledReason == rhs.disabledReason &&
            lhs.id == rhs.id &&
            lhs.pushProvider == rhs.pushProvider &&
            lhs.pushProviderName == rhs.pushProviderName &&
            lhs.userId == rhs.userId &&
            lhs.voip == rhs.voip
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(disabled)
        hasher.combine(disabledReason)
        hasher.combine(id)
        hasher.combine(pushProvider)
        hasher.combine(pushProviderName)
        hasher.combine(userId)
        hasher.combine(voip)
    }
}
