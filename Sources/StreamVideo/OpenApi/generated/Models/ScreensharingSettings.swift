//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ScreensharingSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var accessRequestEnabled: Bool
    public var enabled: Bool
    public var targetResolution: TargetResolution?

    public init(accessRequestEnabled: Bool, enabled: Bool, targetResolution: TargetResolution? = nil) {
        self.accessRequestEnabled = accessRequestEnabled
        self.enabled = enabled
        self.targetResolution = targetResolution
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case enabled
        case targetResolution = "target_resolution"
    }
    
    public static func == (lhs: ScreensharingSettings, rhs: ScreensharingSettings) -> Bool {
        lhs.accessRequestEnabled == rhs.accessRequestEnabled &&
            lhs.enabled == rhs.enabled &&
            lhs.targetResolution == rhs.targetResolution
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessRequestEnabled)
        hasher.combine(enabled)
        hasher.combine(targetResolution)
    }
}
