//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A recurring quiet-hours schedule: while any quiet window is active, push notifications for the user are suppressed. Suppressed notifications are dropped, not delayed.
public final class PushScheduleResponse: @unchecked Sendable, Decodable {
    /// The quiet windows. Push is suppressed while any rule is active.
    public var quietHours: [QuietHoursRuleResponse]
    /// IANA time zone name the quiet windows are evaluated in, for example Europe/Amsterdam.
    public var timezone: String

    public init(quietHours: [QuietHoursRuleResponse], timezone: String) {
        self.quietHours = quietHours
        self.timezone = timezone
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.quietHours = try container.decode([QuietHoursRuleResponse].self, forKey: .quietHours)
        self.timezone = try container.decode(String.self, forKey: .timezone)
    }
}

extension PushScheduleResponse: Hashable {
    public static func == (lhs: PushScheduleResponse, rhs: PushScheduleResponse) -> Bool {
        lhs.quietHours == rhs.quietHours &&
            lhs.timezone == rhs.timezone
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(quietHours)
        hasher.combine(timezone)
    }
}
