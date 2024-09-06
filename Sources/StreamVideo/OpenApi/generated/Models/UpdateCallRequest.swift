//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]?
    public var settingsOverride: CallSettingsRequest?
    public var startsAt: Date?

    public init(custom: [String: RawJSON]? = nil, settingsOverride: CallSettingsRequest? = nil, startsAt: Date? = nil) {
        self.custom = custom
        self.settingsOverride = settingsOverride
        self.startsAt = startsAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case settingsOverride = "settings_override"
        case startsAt = "starts_at"
    }
}
