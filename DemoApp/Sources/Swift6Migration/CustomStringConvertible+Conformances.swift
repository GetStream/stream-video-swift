//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

#if compiler(>=6.0)
extension TranscriptionSettings.Mode: @retroactive CustomStringConvertible {}
extension TranscriptionSettings.ClosedCaptionMode: @retroactive CustomStringConvertible {}
extension TranscriptionSettings.Language: @retroactive CustomStringConvertible {}
#else
extension TranscriptionSettings.Mode: CustomStringConvertible {}
extension TranscriptionSettings.ClosedCaptionMode: CustomStringConvertible {}
extension TranscriptionSettings.Language: CustomStringConvertible {}
#endif

extension TranscriptionSettings.Mode {
    public var description: String {
        switch self {
        case .autoOn:
            "auto-on"
        case .available:
            "Available"
        case .disabled:
            "Disabled"
        case .unknown:
            "Unknown"
        }
    }
}

extension TranscriptionSettings.ClosedCaptionMode {
    public var description: String {
        switch self {
        case .autoOn:
            "auto-on"
        case .available:
            "Available"
        case .disabled:
            "Disabled"
        case .unknown:
            "Unknown"
        }
    }
}

extension TranscriptionSettings.Language {
    public var description: String {
        switch self {
        case .ar: "Arabic"
        case .auto: "Auto"
        case .ca: "Catalan"
        case .cs: "Czech"
        case .da: "Danish"
        case .de: "German"
        case .el: "Greek"
        case .en: "English"
        case .es: "Spanish"
        case .fi: "Finnish"
        case .fr: "French"
        case .he: "Hebrew"
        case .hi: "Hindi"
        case .hr: "Croatian"
        case .hu: "Hungarian"
        case .id: "Indonesian"
        case .it: "Italian"
        case .ja: "Japanese"
        case .ko: "Korean"
        case .ms: "Malay"
        case .nl: "Dutch"
        case .no: "Norwegian"
        case .pl: "Polish"
        case .pt: "Portuguese"
        case .ro: "Romanian"
        case .ru: "Russian"
        case .sv: "Swedish"
        case .ta: "Tamil"
        case .th: "Thai"
        case .tl: "Tagalog"
        case .tr: "Turkish"
        case .uk: "Ukrainian"
        case .zh: "Chinese"
        case .unknown:
            "Unknown"
        }
    }
}
