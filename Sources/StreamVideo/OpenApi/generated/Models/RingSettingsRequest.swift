//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct RingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
