//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var autoCancelTimeoutMs: Int
    public var incomingCallTimeoutMs: Int
    public var missedCallTimeoutMs: Int?

    public init(autoCancelTimeoutMs: Int, incomingCallTimeoutMs: Int, missedCallTimeoutMs: Int? = nil) {
        self.autoCancelTimeoutMs = autoCancelTimeoutMs
        self.incomingCallTimeoutMs = incomingCallTimeoutMs
        self.missedCallTimeoutMs = missedCallTimeoutMs
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoCancelTimeoutMs = "auto_cancel_timeout_ms"
        case incomingCallTimeoutMs = "incoming_call_timeout_ms"
        case missedCallTimeoutMs = "missed_call_timeout_ms"
    }
    
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
