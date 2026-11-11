//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// The push preference details.
public final class PushPreferencesResponse: Sendable, Decodable {
    public let callLevel: String?
    /// If provided the notifications will be disabled until the set date.
    public let disabledUntil: Date?
    /// A recurring quiet-hours schedule: while any quiet window is active, push notifications for the user are suppressed. Suppressed notifications are dropped, not delayed.
    public let schedule: PushScheduleResponse?

    public init(callLevel: String? = nil, disabledUntil: Date? = nil, schedule: PushScheduleResponse? = nil) {
        self.callLevel = callLevel
        self.disabledUntil = disabledUntil
        self.schedule = schedule
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callLevel = try container.decodeIfPresent(String.self, forKey: .callLevel)
        self.disabledUntil = try container.decodeIfPresent(Date.self, forKey: .disabledUntil)
        self.schedule = try container.decodeIfPresent(PushScheduleResponse.self, forKey: .schedule)
    }
}

extension PushPreferencesResponse: Hashable {
    public static func == (lhs: PushPreferencesResponse, rhs: PushPreferencesResponse) -> Bool {
        lhs.callLevel == rhs.callLevel &&
            lhs.disabledUntil == rhs.disabledUntil &&
            lhs.schedule == rhs.schedule
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callLevel)
        hasher.combine(disabledUntil)
        hasher.combine(schedule)
    }
}
