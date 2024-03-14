//
// StatsOptions.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct StatsOptions: Codable, JSONEncodable, Hashable {
    public var reportingIntervalMs: Int

    public init(reportingIntervalMs: Int) {
        self.reportingIntervalMs = reportingIntervalMs
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reportingIntervalMs = "reporting_interval_ms"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reportingIntervalMs, forKey: .reportingIntervalMs)
    }
}
