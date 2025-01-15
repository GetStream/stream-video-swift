//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SessionSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var inactivityTimeoutSeconds: Int

    public init(inactivityTimeoutSeconds: Int) {
        self.inactivityTimeoutSeconds = inactivityTimeoutSeconds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case inactivityTimeoutSeconds = "inactivity_timeout_seconds"
    }
    
    public static func == (lhs: SessionSettingsRequest, rhs: SessionSettingsRequest) -> Bool {
        lhs.inactivityTimeoutSeconds == rhs.inactivityTimeoutSeconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(inactivityTimeoutSeconds)
    }
}
