//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class VideoSettingsRequestCameraFacing: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let back = VideoSettingsRequestCameraFacing(rawValue: "back")
    public static let external = VideoSettingsRequestCameraFacing(rawValue: "external")
    public static let front = VideoSettingsRequestCameraFacing(rawValue: "front")
}

public final class VideoSettingsRequest: Sendable, Encodable, JSONEncodable {
    public let accessRequestEnabled: Bool?
    public let cameraDefaultOn: Bool?
    public let cameraFacing: VideoSettingsRequestCameraFacing?
    public let enabled: Bool?
    public let targetResolution: TargetResolution?

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
