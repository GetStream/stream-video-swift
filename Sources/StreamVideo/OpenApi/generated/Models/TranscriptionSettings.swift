//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class TranscriptionSettings: @unchecked Sendable, Decodable {
    
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
    public var speechSegmentConfig: SpeechSegmentConfig?
    public var translation: TranslationSettings?

    public init(
        closedCaptionMode: TranscriptionSettingsClosedCaptionMode,
        language: TranscriptionSettingsLanguage,
        mode: TranscriptionSettingsMode,
        speechSegmentConfig: SpeechSegmentConfig? = nil,
        translation: TranslationSettings? = nil
    ) {
        self.closedCaptionMode = closedCaptionMode
        self.language = language
        self.mode = mode
        self.speechSegmentConfig = speechSegmentConfig
        self.translation = translation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.closedCaptionMode = try container.decode(TranscriptionSettingsClosedCaptionMode.self, forKey: .closedCaptionMode)
        self.language = try container.decode(TranscriptionSettingsLanguage.self, forKey: .language)
        self.mode = try container.decode(TranscriptionSettingsMode.self, forKey: .mode)
        self.speechSegmentConfig = try container.decodeIfPresent(SpeechSegmentConfig.self, forKey: .speechSegmentConfig)
        self.translation = try container.decodeIfPresent(TranslationSettings.self, forKey: .translation)
    }
}

extension TranscriptionSettings: Hashable {
    public static func == (lhs: TranscriptionSettings, rhs: TranscriptionSettings) -> Bool {
        lhs.closedCaptionMode == rhs.closedCaptionMode &&
            lhs.language == rhs.language &&
            lhs.mode == rhs.mode &&
            lhs.speechSegmentConfig == rhs.speechSegmentConfig &&
            lhs.translation == rhs.translation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(closedCaptionMode)
        hasher.combine(language)
        hasher.combine(mode)
        hasher.combine(speechSegmentConfig)
        hasher.combine(translation)
    }
}
