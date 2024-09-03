//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct VideoSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var accessRequestEnabled: Bool? = nil
    public var cameraDefaultOn: Bool? = nil
    public var cameraFacing: String? = nil
    public var enabled: Bool? = nil
    public var targetResolution: TargetResolution? = nil

    public init(
        accessRequestEnabled: Bool? = nil,
        cameraDefaultOn: Bool? = nil,
        cameraFacing: String? = nil,
        enabled: Bool? = nil,
        targetResolution: TargetResolution? = nil
    ) {
        self.accessRequestEnabled = accessRequestEnabled
        self.cameraDefaultOn = cameraDefaultOn
        self.cameraFacing = cameraFacing
        self.enabled = enabled
        self.targetResolution = targetResolution
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case cameraDefaultOn = "camera_default_on"
        case cameraFacing = "camera_facing"
        case enabled
        case targetResolution = "target_resolution"
    }
}
