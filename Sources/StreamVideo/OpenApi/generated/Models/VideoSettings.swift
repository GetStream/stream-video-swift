//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class VideoSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum CameraFacing: String, Sendable, Codable, CaseIterable {
        case back
        case external
        case front
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
    
    public var accessRequestEnabled: Bool
    public var cameraDefaultOn: Bool
    public var cameraFacing: CameraFacing
    public var enabled: Bool
    public var targetResolution: TargetResolution

    public init(
        accessRequestEnabled: Bool,
        cameraDefaultOn: Bool,
        cameraFacing: CameraFacing,
        enabled: Bool,
        targetResolution: TargetResolution
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
    
    public static func == (lhs: VideoSettings, rhs: VideoSettings) -> Bool {
        lhs.accessRequestEnabled == rhs.accessRequestEnabled &&
            lhs.cameraDefaultOn == rhs.cameraDefaultOn &&
            lhs.cameraFacing == rhs.cameraFacing &&
            lhs.enabled == rhs.enabled &&
            lhs.targetResolution == rhs.targetResolution
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessRequestEnabled)
        hasher.combine(cameraDefaultOn)
        hasher.combine(cameraFacing)
        hasher.combine(enabled)
        hasher.combine(targetResolution)
    }
}
