//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SessionSettingsResponse: @unchecked Sendable, Decodable {
    public var inactivityTimeoutSeconds: Int

    public init(inactivityTimeoutSeconds: Int) {
        self.inactivityTimeoutSeconds = inactivityTimeoutSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.inactivityTimeoutSeconds = try container.decode(Int.self, forKey: .inactivityTimeoutSeconds)
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
