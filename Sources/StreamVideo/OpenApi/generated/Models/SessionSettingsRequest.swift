//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SessionSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var inactivityTimeoutSeconds: Int

    public init(inactivityTimeoutSeconds: Int) {
        self.inactivityTimeoutSeconds = inactivityTimeoutSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.inactivityTimeoutSeconds = try container.decode(Int.self, forKey: .inactivityTimeoutSeconds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(inactivityTimeoutSeconds, forKey: .inactivityTimeoutSeconds)
    }
}

extension SessionSettingsRequest: Hashable {
    public static func == (lhs: SessionSettingsRequest, rhs: SessionSettingsRequest) -> Bool {
        lhs.inactivityTimeoutSeconds == rhs.inactivityTimeoutSeconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(inactivityTimeoutSeconds)
    }
}
