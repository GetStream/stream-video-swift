//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RawRecordingSettingsResponse: @unchecked Sendable, Decodable {
    
    public enum RawRecordingSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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

    public var audioOnly: Bool?
    public var mode: RawRecordingSettingsResponseMode

    public init(audioOnly: Bool? = nil, mode: RawRecordingSettingsResponseMode) {
        self.audioOnly = audioOnly
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.audioOnly = try container.decodeIfPresent(Bool.self, forKey: .audioOnly)
        self.mode = try container.decode(RawRecordingSettingsResponseMode.self, forKey: .mode)
    }
}

extension RawRecordingSettingsResponse: Hashable {
    public static func == (lhs: RawRecordingSettingsResponse, rhs: RawRecordingSettingsResponse) -> Bool {
        lhs.audioOnly == rhs.audioOnly &&
            lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audioOnly)
        hasher.combine(mode)
    }
}
