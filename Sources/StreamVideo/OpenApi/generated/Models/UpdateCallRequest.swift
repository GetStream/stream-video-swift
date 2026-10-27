//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Request for updating a call
public final class UpdateCallRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// Custom data for this object
    public var custom: [String: RawJSON]?
    public var settingsOverride: CallSettingsRequest?
    /// the time the call is scheduled to start
    public var startsAt: Date?

    public init(custom: [String: RawJSON]? = nil, settingsOverride: CallSettingsRequest? = nil, startsAt: Date? = nil) {
        self.custom = custom
        self.settingsOverride = settingsOverride
        self.startsAt = startsAt
    }

    public enum CodingKeys: String, CodingKey {
        case custom
        case settingsOverride = "settings_override"
        case startsAt = "starts_at"
    }
}

extension UpdateCallRequest: Hashable {
    public static func == (lhs: UpdateCallRequest, rhs: UpdateCallRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.settingsOverride == rhs.settingsOverride &&
            lhs.startsAt == rhs.startsAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(settingsOverride)
        hasher.combine(startsAt)
    }
}
