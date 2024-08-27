//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct RecordSettingsRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public enum Mode: String, Codable, CaseIterable {
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
    
    public var audioOnly: Bool? = nil
    public var mode: Mode
    public var quality: String? = nil

    public init(audioOnly: Bool? = nil, mode: Mode, quality: String? = nil) {
        self.audioOnly = audioOnly
        self.mode = mode
        self.quality = quality
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audioOnly = "audio_only"
        case mode
        case quality
    }
}
