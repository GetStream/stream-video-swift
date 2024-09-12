//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class PushNotificationSettingsInput: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var disabled: NullBool?
    public var disabledUntil: NullTime?

    public init(disabled: NullBool? = nil, disabledUntil: NullTime? = nil) {
        self.disabled = disabled
        self.disabledUntil = disabledUntil
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case disabled
        case disabledUntil = "disabled_until"
    }
    
    public static func == (lhs: PushNotificationSettingsInput, rhs: PushNotificationSettingsInput) -> Bool {
        lhs.disabled == rhs.disabled &&
            lhs.disabledUntil == rhs.disabledUntil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(disabled)
        hasher.combine(disabledUntil)
    }
}
