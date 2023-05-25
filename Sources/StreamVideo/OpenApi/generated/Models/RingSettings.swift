//
// RingSettings.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





internal struct RingSettings: Codable, JSONEncodable, Hashable {

    internal var autoCancelTimeoutMs: Int
    internal var incomingCallTimeoutMs: Int

    internal init(autoCancelTimeoutMs: Int, incomingCallTimeoutMs: Int) {
        self.autoCancelTimeoutMs = autoCancelTimeoutMs
        self.incomingCallTimeoutMs = incomingCallTimeoutMs
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case autoCancelTimeoutMs = "auto_cancel_timeout_ms"
        case incomingCallTimeoutMs = "incoming_call_timeout_ms"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(autoCancelTimeoutMs, forKey: .autoCancelTimeoutMs)
        try container.encode(incomingCallTimeoutMs, forKey: .incomingCallTimeoutMs)
    }
}

