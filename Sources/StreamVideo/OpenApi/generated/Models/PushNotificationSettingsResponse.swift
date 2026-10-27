//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
public final class PushNotificationSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var disabled: Bool?
    public var disabledUntil: Date?

    public init(disabled: Bool? = nil, disabledUntil: Date? = nil) {
        self.disabled = disabled
        self.disabledUntil = disabledUntil
    }
    
    public enum CodingKeys: String, CodingKey {
        case disabled
        case disabledUntil = "disabled_until"
    }
    
    public static func == (lhs: PushNotificationSettingsResponse, rhs: PushNotificationSettingsResponse) -> Bool {
        lhs.disabled == rhs.disabled &&
            lhs.disabledUntil == rhs.disabledUntil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(disabled)
        hasher.combine(disabledUntil)
    }
}
