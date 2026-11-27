//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ReportHLSStatsRequest: Sendable, Encodable, JSONEncodable {
    
    public enum ReportHLSStatsRequestEndReason: String, Sendable, Codable, CaseIterable {
        case error
        case left
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public enum ReportHLSStatsRequestType: String, Sendable, Codable, CaseIterable {
        case ended
        case started
        case stats
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    public let browser: String?
    public let browserVersion: String?
    /// Call session the viewer is watching
    public let callSessionId: String
    /// Why playback ended, on an ended report. One of: left, error. Defaults to left
    public let endReason: ReportHLSStatsRequestEndReason?
    /// Player error code when end_reason is error
    public let errorCode: String?
    /// Player events since the previous report, shown on the participant timeline
    public let events: [HLSPlayerEvent]?
    public let os: String?
    public let osVersion: String?
    public let sdk: String?
    public let sdkVersion: String?
    public let stats: HLSPlaybackStats?
    /// playback.stats_token from the join call response that sent the viewer to HLS
    public let statsToken: String
    /// When the reported state happened on the client, Unix time in milliseconds (UTC). Defaults to the time the server receives the report; a time in the future is capped to it
    public let timestamp: Int
    /// Report type. One of: started, stats, ended
    public let type: ReportHLSStatsRequestType
    /// SDK session ID for this call, the same value the SDK sends for its WebRTC sessions. Links the viewer's HLS and WebRTC sessions in call stats
    public let unifiedSessionId: String
    /// Client-generated ID of this playback session, constant from started to ended
    public let userSessionId: String

    public init(
        browser: String? = nil,
        browserVersion: String? = nil,
        callSessionId: String,
        endReason: ReportHLSStatsRequestEndReason? = nil,
        errorCode: String? = nil,
        events: [HLSPlayerEvent]? = nil,
        os: String? = nil,
        osVersion: String? = nil,
        sdk: String? = nil,
        sdkVersion: String? = nil,
        stats: HLSPlaybackStats? = nil,
        statsToken: String,
        timestamp: Int,
        type: ReportHLSStatsRequestType,
        unifiedSessionId: String,
        userSessionId: String
    ) {
        self.browser = browser
        self.browserVersion = browserVersion
        self.callSessionId = callSessionId
        self.endReason = endReason
        self.errorCode = errorCode
        self.events = events
        self.os = os
        self.osVersion = osVersion
        self.sdk = sdk
        self.sdkVersion = sdkVersion
        self.stats = stats
        self.statsToken = statsToken
        self.timestamp = timestamp
        self.type = type
        self.unifiedSessionId = unifiedSessionId
        self.userSessionId = userSessionId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(browser, forKey: .browser)
        try container.encodeIfPresent(browserVersion, forKey: .browserVersion)
        try container.encode(callSessionId, forKey: .callSessionId)
        try container.encodeIfPresent(endReason, forKey: .endReason)
        try container.encodeIfPresent(errorCode, forKey: .errorCode)
        try container.encodeIfPresent(events, forKey: .events)
        try container.encodeIfPresent(os, forKey: .os)
        try container.encodeIfPresent(osVersion, forKey: .osVersion)
        try container.encodeIfPresent(sdk, forKey: .sdk)
        try container.encodeIfPresent(sdkVersion, forKey: .sdkVersion)
        try container.encodeIfPresent(stats, forKey: .stats)
        try container.encode(statsToken, forKey: .statsToken)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(unifiedSessionId, forKey: .unifiedSessionId)
        try container.encode(userSessionId, forKey: .userSessionId)
    }
}

extension ReportHLSStatsRequest: Hashable {
    public static func == (lhs: ReportHLSStatsRequest, rhs: ReportHLSStatsRequest) -> Bool {
        lhs.browser == rhs.browser &&
            lhs.browserVersion == rhs.browserVersion &&
            lhs.callSessionId == rhs.callSessionId &&
            lhs.endReason == rhs.endReason &&
            lhs.errorCode == rhs.errorCode &&
            lhs.events == rhs.events &&
            lhs.os == rhs.os &&
            lhs.osVersion == rhs.osVersion &&
            lhs.sdk == rhs.sdk &&
            lhs.sdkVersion == rhs.sdkVersion &&
            lhs.stats == rhs.stats &&
            lhs.statsToken == rhs.statsToken &&
            lhs.timestamp == rhs.timestamp &&
            lhs.type == rhs.type &&
            lhs.unifiedSessionId == rhs.unifiedSessionId &&
            lhs.userSessionId == rhs.userSessionId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(browser)
        hasher.combine(browserVersion)
        hasher.combine(callSessionId)
        hasher.combine(endReason)
        hasher.combine(errorCode)
        hasher.combine(events)
        hasher.combine(os)
        hasher.combine(osVersion)
        hasher.combine(sdk)
        hasher.combine(sdkVersion)
        hasher.combine(stats)
        hasher.combine(statsToken)
        hasher.combine(timestamp)
        hasher.combine(type)
        hasher.combine(unifiedSessionId)
        hasher.combine(userSessionId)
    }
}
