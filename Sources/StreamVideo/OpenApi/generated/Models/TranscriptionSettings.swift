//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class TranscriptionSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public var closedCaptionMode: String
    public var languages: [String]
    public var mode: Mode

    public init(closedCaptionMode: String, languages: [String], mode: Mode) {
        self.closedCaptionMode = closedCaptionMode
        self.languages = languages
        self.mode = mode
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case closedCaptionMode = "closed_caption_mode"
        case languages
        case mode
    }
    
    public static func == (lhs: TranscriptionSettings, rhs: TranscriptionSettings) -> Bool {
        lhs.closedCaptionMode == rhs.closedCaptionMode &&
            lhs.languages == rhs.languages &&
            lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(closedCaptionMode)
        hasher.combine(languages)
        hasher.combine(mode)
    }
}
