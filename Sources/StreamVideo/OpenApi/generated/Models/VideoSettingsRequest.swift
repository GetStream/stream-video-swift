//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct VideoSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var accessRequestEnabled: Bool?
    public var cameraDefaultOn: Bool?
    public var cameraFacing: String?
    public var enabled: Bool?
    public var targetResolution: TargetResolution?

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
