//
// ListDevicesResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct ListDevicesResponse: Codable, JSONEncodable, Hashable {
    /** List of devices */
    public var devices: [Device]
    public var duration: String

    public init(devices: [Device], duration: String) {
        self.devices = devices
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case devices
        case duration
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(devices, forKey: .devices)
        try container.encode(duration, forKey: .duration)
    }
}

