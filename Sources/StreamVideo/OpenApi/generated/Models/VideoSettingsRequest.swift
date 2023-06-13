//
// VideoSettingsRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





public struct VideoSettingsRequest: Codable, JSONEncodable, Hashable {

    public enum CameraFacing: String, Codable, CaseIterable {
        case front = "front"
        case back = "back"
        case external = "external"
    }
    public var accessRequestEnabled: Bool?
    public var cameraDefaultOn: Bool?
    public var cameraFacing: CameraFacing?
    public var enabled: Bool?
    public var targetResolution: TargetResolutionRequest?

    public init(accessRequestEnabled: Bool? = nil, cameraDefaultOn: Bool? = nil, cameraFacing: CameraFacing? = nil, enabled: Bool? = nil, targetResolution: TargetResolutionRequest? = nil) {
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

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(accessRequestEnabled, forKey: .accessRequestEnabled)
        try container.encodeIfPresent(cameraDefaultOn, forKey: .cameraDefaultOn)
        try container.encodeIfPresent(cameraFacing, forKey: .cameraFacing)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(targetResolution, forKey: .targetResolution)
    }
}

