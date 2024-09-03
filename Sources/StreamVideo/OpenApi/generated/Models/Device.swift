//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Device: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var disabled: Bool? = nil
    public var disabledReason: String? = nil
    public var id: String
    public var pushProvider: String
    public var pushProviderName: String? = nil
    public var userId: String
    public var voip: Bool? = nil

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
}
