//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class TranscriptionSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum TranscriptionSettingsRequestClosedCaptionMode: String, Sendable, Codable, CaseIterable {
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
    
    public enum TranscriptionSettingsRequestLanguage: String, Sendable, Codable, CaseIterable {
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
    
    public enum TranscriptionSettingsRequestMode: String, Sendable, Codable, CaseIterable {
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

    public var closedCaptionMode: TranscriptionSettingsRequestClosedCaptionMode?
    public var language: TranscriptionSettingsRequestLanguage?
    public var mode: TranscriptionSettingsRequestMode

    public init(
        closedCaptionMode: TranscriptionSettingsRequestClosedCaptionMode? = nil,
        language: TranscriptionSettingsRequestLanguage? = nil,
        mode: TranscriptionSettingsRequestMode
    ) {
        self.closedCaptionMode = closedCaptionMode
        self.language = language
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.closedCaptionMode = try container.decodeIfPresent(
            TranscriptionSettingsRequestClosedCaptionMode.self,
            forKey: .closedCaptionMode
        )
        self.language = try container.decodeIfPresent(TranscriptionSettingsRequestLanguage.self, forKey: .language)
        self.mode = try container.decode(TranscriptionSettingsRequestMode.self, forKey: .mode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(closedCaptionMode, forKey: .closedCaptionMode)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encode(mode, forKey: .mode)
    }
}

extension TranscriptionSettingsRequest: Hashable {
    public static func == (lhs: TranscriptionSettingsRequest, rhs: TranscriptionSettingsRequest) -> Bool {
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
