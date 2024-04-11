//
// UserStats.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct UserStats: Codable, JSONEncodable, Hashable {
    public var info: UserInfoResponse
    public var sessionStats: [UserSessionStats]

    public init(info: UserInfoResponse, sessionStats: [UserSessionStats]) {
        self.info = info
        self.sessionStats = sessionStats
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case info
        case sessionStats = "session_stats"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(info, forKey: .info)
        try container.encode(sessionStats, forKey: .sessionStats)
    }
}
