//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RingSettings: @unchecked Sendable, Decodable {
    public var autoCancelTimeoutMs: Int
    public var incomingCallTimeoutMs: Int
    public var missedCallTimeoutMs: Int

    public init(autoCancelTimeoutMs: Int, incomingCallTimeoutMs: Int, missedCallTimeoutMs: Int) {
        self.autoCancelTimeoutMs = autoCancelTimeoutMs
        self.incomingCallTimeoutMs = incomingCallTimeoutMs
        self.missedCallTimeoutMs = missedCallTimeoutMs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.autoCancelTimeoutMs = try container.decode(Int.self, forKey: .autoCancelTimeoutMs)
        self.incomingCallTimeoutMs = try container.decode(Int.self, forKey: .incomingCallTimeoutMs)
        self.missedCallTimeoutMs = try container.decode(Int.self, forKey: .missedCallTimeoutMs)
    }
}

extension RingSettings: Hashable {
    public static func == (lhs: RingSettings, rhs: RingSettings) -> Bool {
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
