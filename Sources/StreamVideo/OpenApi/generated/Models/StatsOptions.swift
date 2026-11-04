//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StatsOptions: @unchecked Sendable, Codable, JSONEncodable {
    public var enableRtcStats: Bool
    public var reportingIntervalMs: Int

    public init(enableRtcStats: Bool, reportingIntervalMs: Int) {
        self.enableRtcStats = enableRtcStats
        self.reportingIntervalMs = reportingIntervalMs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enableRtcStats = try container.decode(Bool.self, forKey: .enableRtcStats)
        self.reportingIntervalMs = try container.decode(Int.self, forKey: .reportingIntervalMs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(enableRtcStats, forKey: .enableRtcStats)
        try container.encode(reportingIntervalMs, forKey: .reportingIntervalMs)
    }
}

extension StatsOptions: Hashable {
    public static func == (lhs: StatsOptions, rhs: StatsOptions) -> Bool {
        lhs.enableRtcStats == rhs.enableRtcStats &&
            lhs.reportingIntervalMs == rhs.reportingIntervalMs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableRtcStats)
        hasher.combine(reportingIntervalMs)
    }
}
