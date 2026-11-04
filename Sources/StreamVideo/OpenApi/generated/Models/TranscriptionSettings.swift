//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class TranscriptionSettings: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum TranscriptionSettingsClosedCaptionMode: String, Sendable, Codable, CaseIterable {
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
    
    public enum TranscriptionSettingsLanguage: String, Sendable, Codable, CaseIterable {
        case ar
        case auto
        case ca
        case cs
        case da
        case de
        case el
        case en
        case es
        case fi
        case fr
        case he
        case hi
        case hr
        case hu
        case id
        case it
        case ja
        case ko
        case ms
        case nl
        case no
        case pl
        case pt
        case ro
        case ru
        case sv
        case ta
        case th
        case tl
        case tr
        case uk
        case zh
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
    
    public enum TranscriptionSettingsMode: String, Sendable, Codable, CaseIterable {
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

    public var closedCaptionMode: TranscriptionSettingsClosedCaptionMode
    public var language: TranscriptionSettingsLanguage
    public var mode: TranscriptionSettingsMode

    public init(
        closedCaptionMode: TranscriptionSettingsClosedCaptionMode,
        language: TranscriptionSettingsLanguage,
        mode: TranscriptionSettingsMode
    ) {
        self.closedCaptionMode = closedCaptionMode
        self.language = language
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.closedCaptionMode = try container.decode(TranscriptionSettingsClosedCaptionMode.self, forKey: .closedCaptionMode)
        self.language = try container.decode(TranscriptionSettingsLanguage.self, forKey: .language)
        self.mode = try container.decode(TranscriptionSettingsMode.self, forKey: .mode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(closedCaptionMode, forKey: .closedCaptionMode)
        try container.encode(language, forKey: .language)
        try container.encode(mode, forKey: .mode)
    }
}

extension TranscriptionSettings: Hashable {
    public static func == (lhs: TranscriptionSettings, rhs: TranscriptionSettings) -> Bool {
        lhs.closedCaptionMode == rhs.closedCaptionMode &&
            lhs.language == rhs.language &&
            lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(closedCaptionMode)
        hasher.combine(language)
        hasher.combine(mode)
    }
}
