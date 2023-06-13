//
// TranscriptionSettings.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





public struct TranscriptionSettings: Codable, JSONEncodable, Hashable {

    public enum Mode: String, Codable, CaseIterable {
        case available = "available"
        case disabled = "disabled"
        case autoOn = "auto-on"
    }
    public var closedCaptionMode: String
    public var mode: Mode

    public init(closedCaptionMode: String, mode: Mode) {
        self.closedCaptionMode = closedCaptionMode
        self.mode = mode
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case closedCaptionMode = "closed_caption_mode"
        case mode
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(closedCaptionMode, forKey: .closedCaptionMode)
        try container.encode(mode, forKey: .mode)
    }
}

