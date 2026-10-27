//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class VideoSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum VideoSettingsRequestCameraFacing: String, Sendable, Codable, CaseIterable {
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

    public var accessRequestEnabled: Bool?
    public var cameraDefaultOn: Bool?
    public var cameraFacing: VideoSettingsRequestCameraFacing?
    public var enabled: Bool?
    public var targetResolution: TargetResolution?

    public init(
        accessRequestEnabled: Bool? = nil,
        cameraDefaultOn: Bool? = nil,
        cameraFacing: VideoSettingsRequestCameraFacing? = nil,
        enabled: Bool? = nil,
        targetResolution: TargetResolution? = nil
    ) {
        self.accessRequestEnabled = accessRequestEnabled
        self.cameraDefaultOn = cameraDefaultOn
        self.cameraFacing = cameraFacing
        self.enabled = enabled
        self.targetResolution = targetResolution
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.accessRequestEnabled = try container.decodeIfPresent(Bool.self, forKey: .accessRequestEnabled)
        self.cameraDefaultOn = try container.decodeIfPresent(Bool.self, forKey: .cameraDefaultOn)
        self.cameraFacing = try container.decodeIfPresent(VideoSettingsRequestCameraFacing.self, forKey: .cameraFacing)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.targetResolution = try container.decodeIfPresent(TargetResolution.self, forKey: .targetResolution)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(accessRequestEnabled, forKey: .accessRequestEnabled)
        try container.encodeIfPresent(cameraDefaultOn, forKey: .cameraDefaultOn)
        try container.encodeIfPresent(cameraFacing, forKey: .cameraFacing)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(targetResolution, forKey: .targetResolution)
    }
}

extension VideoSettingsRequest: Hashable {
    public static func == (lhs: VideoSettingsRequest, rhs: VideoSettingsRequest) -> Bool {
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
