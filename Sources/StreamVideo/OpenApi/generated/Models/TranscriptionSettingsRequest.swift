//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class TranscriptionSettingsRequestClosedCaptionMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = TranscriptionSettingsRequestClosedCaptionMode(rawValue: "auto-on")
    public static let available = TranscriptionSettingsRequestClosedCaptionMode(rawValue: "available")
    public static let disabled = TranscriptionSettingsRequestClosedCaptionMode(rawValue: "disabled")
}

public final class TranscriptionSettingsRequestLanguage: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let ar = TranscriptionSettingsRequestLanguage(rawValue: "ar")
    public static let auto = TranscriptionSettingsRequestLanguage(rawValue: "auto")
    public static let bg = TranscriptionSettingsRequestLanguage(rawValue: "bg")
    public static let ca = TranscriptionSettingsRequestLanguage(rawValue: "ca")
    public static let cs = TranscriptionSettingsRequestLanguage(rawValue: "cs")
    public static let da = TranscriptionSettingsRequestLanguage(rawValue: "da")
    public static let de = TranscriptionSettingsRequestLanguage(rawValue: "de")
    public static let el = TranscriptionSettingsRequestLanguage(rawValue: "el")
    public static let en = TranscriptionSettingsRequestLanguage(rawValue: "en")
    public static let es = TranscriptionSettingsRequestLanguage(rawValue: "es")
    public static let et = TranscriptionSettingsRequestLanguage(rawValue: "et")
    public static let fi = TranscriptionSettingsRequestLanguage(rawValue: "fi")
    public static let fr = TranscriptionSettingsRequestLanguage(rawValue: "fr")
    public static let he = TranscriptionSettingsRequestLanguage(rawValue: "he")
    public static let hi = TranscriptionSettingsRequestLanguage(rawValue: "hi")
    public static let hr = TranscriptionSettingsRequestLanguage(rawValue: "hr")
    public static let hu = TranscriptionSettingsRequestLanguage(rawValue: "hu")
    public static let id = TranscriptionSettingsRequestLanguage(rawValue: "id")
    public static let it = TranscriptionSettingsRequestLanguage(rawValue: "it")
    public static let ja = TranscriptionSettingsRequestLanguage(rawValue: "ja")
    public static let ko = TranscriptionSettingsRequestLanguage(rawValue: "ko")
    public static let ms = TranscriptionSettingsRequestLanguage(rawValue: "ms")
    public static let nl = TranscriptionSettingsRequestLanguage(rawValue: "nl")
    public static let no = TranscriptionSettingsRequestLanguage(rawValue: "no")
    public static let pl = TranscriptionSettingsRequestLanguage(rawValue: "pl")
    public static let pt = TranscriptionSettingsRequestLanguage(rawValue: "pt")
    public static let ro = TranscriptionSettingsRequestLanguage(rawValue: "ro")
    public static let ru = TranscriptionSettingsRequestLanguage(rawValue: "ru")
    public static let sk = TranscriptionSettingsRequestLanguage(rawValue: "sk")
    public static let sl = TranscriptionSettingsRequestLanguage(rawValue: "sl")
    public static let sv = TranscriptionSettingsRequestLanguage(rawValue: "sv")
    public static let ta = TranscriptionSettingsRequestLanguage(rawValue: "ta")
    public static let th = TranscriptionSettingsRequestLanguage(rawValue: "th")
    public static let tl = TranscriptionSettingsRequestLanguage(rawValue: "tl")
    public static let tr = TranscriptionSettingsRequestLanguage(rawValue: "tr")
    public static let uk = TranscriptionSettingsRequestLanguage(rawValue: "uk")
    public static let zh = TranscriptionSettingsRequestLanguage(rawValue: "zh")
}

public final class TranscriptionSettingsRequestMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = TranscriptionSettingsRequestMode(rawValue: "auto-on")
    public static let available = TranscriptionSettingsRequestMode(rawValue: "available")
    public static let disabled = TranscriptionSettingsRequestMode(rawValue: "disabled")
}

public final class TranscriptionSettingsRequest: Sendable, Encodable, JSONEncodable {
    public let closedCaptionMode: TranscriptionSettingsRequestClosedCaptionMode?
    public let language: TranscriptionSettingsRequestLanguage?
    public let mode: TranscriptionSettingsRequestMode

    public init(
        closedCaptionMode: TranscriptionSettingsRequestClosedCaptionMode? = nil,
        language: TranscriptionSettingsRequestLanguage? = nil,
        mode: TranscriptionSettingsRequestMode
    ) {
        self.closedCaptionMode = closedCaptionMode
        self.language = language
        self.mode = mode
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
