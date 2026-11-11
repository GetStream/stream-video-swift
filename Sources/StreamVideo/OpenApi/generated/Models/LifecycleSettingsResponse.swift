//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// LifecycleSettings is the payload for call lifecycle settings
public final class LifecycleSettingsResponse: Sendable, Decodable {
    
    public enum LifecycleSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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
    public let mode: LifecycleSettingsResponseMode

    public init(mode: LifecycleSettingsResponseMode) {
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(LifecycleSettingsResponseMode.self, forKey: .mode)
    }
}

extension LifecycleSettingsResponse: Hashable {
    public static func == (lhs: LifecycleSettingsResponse, rhs: LifecycleSettingsResponse) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
