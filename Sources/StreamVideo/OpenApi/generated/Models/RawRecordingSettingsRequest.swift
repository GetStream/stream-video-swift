//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RawRecordingSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    
    public enum RawRecordingSettingsRequestMode: String, Sendable, Codable, CaseIterable {
        case autoOn = "auto-on"
        case available
        case disabled
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

    /// If true, only audio tracks will be recorded
    public var audioOnly: Bool?
    /// Recording mode. One of: available, disabled, auto-on
    public var mode: RawRecordingSettingsRequestMode

    public init(audioOnly: Bool? = nil, mode: RawRecordingSettingsRequestMode) {
        self.audioOnly = audioOnly
        self.mode = mode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(audioOnly, forKey: .audioOnly)
        try container.encode(mode, forKey: .mode)
    }
}

extension RawRecordingSettingsRequest: Hashable {
    public static func == (lhs: RawRecordingSettingsRequest, rhs: RawRecordingSettingsRequest) -> Bool {
        lhs.audioOnly == rhs.audioOnly &&
            lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audioOnly)
        hasher.combine(mode)
    }
}
