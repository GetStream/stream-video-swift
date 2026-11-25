//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StatsOptions: Sendable, Decodable {
    /// Whether to send HLS stats reports when playing the call over HLS (beta)
    public let enableHlsStats: Bool?
    /// Whether to send WebRTC stats reports
    public let enableRtcStats: Bool
    /// How often to send HLS stats reports when playing the call over HLS, in milliseconds (beta)
    public let reportingHlsIntervalMs: Int?
    /// How often to send WebRTC stats reports, in milliseconds
    public let reportingIntervalMs: Int

    public init(enableHlsStats: Bool? = nil, enableRtcStats: Bool, reportingHlsIntervalMs: Int? = nil, reportingIntervalMs: Int) {
        self.enableHlsStats = enableHlsStats
        self.enableRtcStats = enableRtcStats
        self.reportingHlsIntervalMs = reportingHlsIntervalMs
        self.reportingIntervalMs = reportingIntervalMs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enableHlsStats = try container.decodeIfPresent(Bool.self, forKey: .enableHlsStats)
        self.enableRtcStats = try container.decode(Bool.self, forKey: .enableRtcStats)
        self.reportingHlsIntervalMs = try container.decodeIfPresent(Int.self, forKey: .reportingHlsIntervalMs)
        self.reportingIntervalMs = try container.decode(Int.self, forKey: .reportingIntervalMs)
    }
}

extension StatsOptions: Hashable {
    public static func == (lhs: StatsOptions, rhs: StatsOptions) -> Bool {
        lhs.enableHlsStats == rhs.enableHlsStats &&
            lhs.enableRtcStats == rhs.enableRtcStats &&
            lhs.reportingHlsIntervalMs == rhs.reportingHlsIntervalMs &&
            lhs.reportingIntervalMs == rhs.reportingIntervalMs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableHlsStats)
        hasher.combine(enableRtcStats)
        hasher.combine(reportingHlsIntervalMs)
        hasher.combine(reportingIntervalMs)
    }
}
