//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// When none of the callees accept a ring call in this time a rejection will be sent by the caller with reason 'timeout' by the SDKs
    public var autoCancelTimeoutMs: Int
    /// When a callee is online but doesn't answer a ring call in this time a rejection will be sent with reason 'timeout' by the SDKs
    public var incomingCallTimeoutMs: Int
    /// When a callee doesn't accept or reject a ring call in this time a missed call event will be sent
    public var missedCallTimeoutMs: Int?

    public init(autoCancelTimeoutMs: Int, incomingCallTimeoutMs: Int, missedCallTimeoutMs: Int? = nil) {
        self.autoCancelTimeoutMs = autoCancelTimeoutMs
        self.incomingCallTimeoutMs = incomingCallTimeoutMs
        self.missedCallTimeoutMs = missedCallTimeoutMs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.autoCancelTimeoutMs = try container.decode(Int.self, forKey: .autoCancelTimeoutMs)
        self.incomingCallTimeoutMs = try container.decode(Int.self, forKey: .incomingCallTimeoutMs)
        self.missedCallTimeoutMs = try container.decodeIfPresent(Int.self, forKey: .missedCallTimeoutMs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(autoCancelTimeoutMs, forKey: .autoCancelTimeoutMs)
        try container.encode(incomingCallTimeoutMs, forKey: .incomingCallTimeoutMs)
        try container.encodeIfPresent(missedCallTimeoutMs, forKey: .missedCallTimeoutMs)
    }
}

extension RingSettingsRequest: Hashable {
    public static func == (lhs: RingSettingsRequest, rhs: RingSettingsRequest) -> Bool {
        lhs.autoCancelTimeoutMs == rhs.autoCancelTimeoutMs &&
            lhs.incomingCallTimeoutMs == rhs.incomingCallTimeoutMs &&
            lhs.missedCallTimeoutMs == rhs.missedCallTimeoutMs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(autoCancelTimeoutMs)
        hasher.combine(incomingCallTimeoutMs)
        hasher.combine(missedCallTimeoutMs)
    }
}
