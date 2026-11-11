//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class LifecycleSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    
    public enum LifecycleSettingsRequestMode: String, Sendable, Codable, CaseIterable {
        case reusable
        case singleUse = "single_use"
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

    /// Call lifecycle mode. One of: reusable, single_use. A single_use call cannot be reused once it has ended; the server ends it when its ring settles without an answer (currently: when the caller cancels the ring). Fixed at call creation
    public var mode: LifecycleSettingsRequestMode?

    public init(mode: LifecycleSettingsRequestMode? = nil) {
        self.mode = mode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(mode, forKey: .mode)
    }
}

extension LifecycleSettingsRequest: Hashable {
    public static func == (lhs: LifecycleSettingsRequest, rhs: LifecycleSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
