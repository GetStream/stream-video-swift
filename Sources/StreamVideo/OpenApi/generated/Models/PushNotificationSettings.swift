//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct PushNotificationSettings: Codable, JSONEncodable, Hashable {

    internal var disabled: Bool?
    internal var disabledUntil: Date?

    internal init(disabled: Bool? = nil, disabledUntil: Date? = nil) {
        self.disabled = disabled
        self.disabledUntil = disabledUntil
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case disabled
        case disabledUntil = "disabled_until"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(disabled, forKey: .disabled)
        try container.encodeIfPresent(disabledUntil, forKey: .disabledUntil)
    }
}
