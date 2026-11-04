//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class VideoSettings: @unchecked Sendable, Decodable {
    
    public enum VideoSettingsCameraFacing: String, Sendable, Codable, CaseIterable {
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
    public var cameraFacing: VideoSettingsCameraFacing
    public var enabled: Bool
    public var targetResolution: TargetResolution

    public init(
        accessRequestEnabled: Bool,
        cameraDefaultOn: Bool,
        cameraFacing: VideoSettingsCameraFacing,
        enabled: Bool,
        targetResolution: TargetResolution
    ) {
        self.accessRequestEnabled = accessRequestEnabled
        self.cameraDefaultOn = cameraDefaultOn
        self.cameraFacing = cameraFacing
        self.enabled = enabled
        self.targetResolution = targetResolution
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.accessRequestEnabled = try container.decode(Bool.self, forKey: .accessRequestEnabled)
        self.cameraDefaultOn = try container.decode(Bool.self, forKey: .cameraDefaultOn)
        self.cameraFacing = try container.decode(VideoSettingsCameraFacing.self, forKey: .cameraFacing)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.targetResolution = try container.decode(TargetResolution.self, forKey: .targetResolution)
    }
}

extension VideoSettings: Hashable {
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
