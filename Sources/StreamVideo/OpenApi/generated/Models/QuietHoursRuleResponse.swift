//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// One recurring quiet window, expressed in local wall-clock time in the schedule's timezone.
public final class QuietHoursRuleResponse: @unchecked Sendable, Decodable {
    /// The days of the week the window opens on, any of mon, tue, wed, thu, fri, sat, sun. A window belongs to the day it opens: ["fri"] with 22:00 to 07:00 is quiet from Friday 22:00 until Saturday 07:00. Omitted means every day.
    public var days: [String]?
    /// When the window closes, as HH:MM local wall-clock time between 00:00 and 24:00. The end is exclusive. An end earlier than start wraps past midnight into the next day.
    public var end: String
    /// When the window opens, as HH:MM local wall-clock time between 00:00 and 23:59.
    public var start: String

    public init(days: [String]? = nil, end: String, start: String) {
        self.days = days
        self.end = end
        self.start = start
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.days = try container.decodeIfPresent([String].self, forKey: .days)
        self.end = try container.decode(String.self, forKey: .end)
        self.start = try container.decode(String.self, forKey: .start)
    }
}

extension QuietHoursRuleResponse: Hashable {
    public static func == (lhs: QuietHoursRuleResponse, rhs: QuietHoursRuleResponse) -> Bool {
        lhs.days == rhs.days &&
            lhs.end == rhs.end &&
            lhs.start == rhs.start
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(days)
        hasher.combine(end)
        hasher.combine(start)
    }
}
