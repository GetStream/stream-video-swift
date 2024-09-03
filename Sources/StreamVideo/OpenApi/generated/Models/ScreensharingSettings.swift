//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ScreensharingSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var accessRequestEnabled: Bool
    public var enabled: Bool
    public var targetResolution: TargetResolution? = nil

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
}
