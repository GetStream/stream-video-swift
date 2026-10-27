//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SessionSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var inactivityTimeoutSeconds: Int

    public init(inactivityTimeoutSeconds: Int) {
        self.inactivityTimeoutSeconds = inactivityTimeoutSeconds
    }

    public enum CodingKeys: String, CodingKey {
        case inactivityTimeoutSeconds = "inactivity_timeout_seconds"
    }
}

extension SessionSettingsResponse: Hashable {
    public static func == (lhs: SessionSettingsResponse, rhs: SessionSettingsResponse) -> Bool {
        lhs.inactivityTimeoutSeconds == rhs.inactivityTimeoutSeconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(inactivityTimeoutSeconds)
    }
}
