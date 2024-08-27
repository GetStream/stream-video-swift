//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ScreensharingSettingsRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var accessRequestEnabled: Bool? = nil
    public var enabled: Bool? = nil
    public var targetResolution: TargetResolution? = nil

    public init(accessRequestEnabled: Bool? = nil, enabled: Bool? = nil, targetResolution: TargetResolution? = nil) {
        self.accessRequestEnabled = accessRequestEnabled
        self.enabled = enabled
        self.targetResolution = targetResolution
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case enabled
        case targetResolution = "target_resolution"
    }
}
