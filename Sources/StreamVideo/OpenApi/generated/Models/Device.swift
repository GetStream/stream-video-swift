//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct Device: Codable, JSONEncodable, Hashable {

    /** Date/time of creation */
    internal var createdAt: Date
    /** Whether device is disabled or not */
    internal var disabled: Bool?
    /** Reason explaining why device had been disabled */
    internal var disabledReason: String?
    internal var id: String
    internal var pushProvider: String
    internal var pushProviderName: String?
    internal var userId: String

    internal init(
        createdAt: Date,
        disabled: Bool? = nil,
        disabledReason: String? = nil,
        id: String,
        pushProvider: String,
        pushProviderName: String? = nil,
        userId: String
    ) {
        self.createdAt = createdAt
        self.disabled = disabled
        self.disabledReason = disabledReason
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.userId = userId
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case disabled
        case disabledReason = "disabled_reason"
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case userId = "user_id"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(disabled, forKey: .disabled)
        try container.encodeIfPresent(disabledReason, forKey: .disabledReason)
        try container.encode(id, forKey: .id)
        try container.encode(pushProvider, forKey: .pushProvider)
        try container.encodeIfPresent(pushProviderName, forKey: .pushProviderName)
        try container.encode(userId, forKey: .userId)
    }
}
