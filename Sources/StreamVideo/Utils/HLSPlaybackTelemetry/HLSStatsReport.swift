//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// One playback report for `POST /video/call/{type}/{id}/hls_stats`.
final class HLSStatsReport: Encodable, Sendable {
    let callSessionId: String
    let userSessionId: String
    let unifiedSessionId: String
    let type: String
    let timestamp: Int64
    let sdk: String
    let sdkVersion: String
    let os: String
    let osVersion: String
    let endReason: String?
    let errorCode: String?
    let stats: HLSPlaybackStats?
    let events: [HLSStatsEvent]

    init(
        callSessionId: String,
        userSessionId: String,
        unifiedSessionId: String,
        type: String,
        timestamp: Int64,
        sdk: String,
        sdkVersion: String,
        os: String,
        osVersion: String,
        endReason: String?,
        errorCode: String?,
        stats: HLSPlaybackStats?,
        events: [HLSStatsEvent]
    ) {
        self.callSessionId = callSessionId
        self.userSessionId = userSessionId
        self.unifiedSessionId = unifiedSessionId
        self.type = type
        self.timestamp = timestamp
        self.sdk = sdk
        self.sdkVersion = sdkVersion
        self.os = os
        self.osVersion = osVersion
        self.endReason = endReason
        self.errorCode = errorCode
        self.stats = stats
        self.events = events
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(callSessionId, forKey: .callSessionId)
        try container.encode(userSessionId, forKey: .userSessionId)
        try container.encode(unifiedSessionId, forKey: .unifiedSessionId)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sdk, forKey: .sdk)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(os, forKey: .os)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encodeIfPresent(endReason, forKey: .endReason)
        try container.encodeIfPresent(errorCode, forKey: .errorCode)
        try container.encodeIfPresent(stats, forKey: .stats)
        if !events.isEmpty {
            try container.encode(events, forKey: .events)
        }
    }
}
