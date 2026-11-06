//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension TranscriptionSettings.Mode {
    var displayName: String {
        switch self {
        case .autoOn:
            return "auto-on"
        case .available:
            return "Available"
        case .disabled:
            return "Disabled"
        default:
            return rawValue
        }
    }
}

extension TranscriptionSettings.ClosedCaptionMode {
    var displayName: String {
        switch self {
        case .autoOn:
            return "auto-on"
        case .available:
            return "Available"
        case .disabled:
            return "Disabled"
        default:
            return rawValue
        }
    }
}

extension TranscriptionSettings.Language {
    var displayName: String {
        switch self {
        case .ar: return "Arabic"
        case .auto: return "Auto"
        case .bg: return "Bulgarian"
        case .ca: return "Catalan"
        case .cs: return "Czech"
        case .da: return "Danish"
        case .de: return "German"
        case .el: return "Greek"
        case .en: return "English"
        case .es: return "Spanish"
        case .et: return "Estonian"
        case .fi: return "Finnish"
        case .fr: return "French"
        case .he: return "Hebrew"
        case .hi: return "Hindi"
        case .hr: return "Croatian"
        case .hu: return "Hungarian"
        case .id: return "Indonesian"
        case .it: return "Italian"
        case .ja: return "Japanese"
        case .ko: return "Korean"
        case .ms: return "Malay"
        case .nl: return "Dutch"
        case .no: return "Norwegian"
        case .pl: return "Polish"
        case .pt: return "Portuguese"
        case .ro: return "Romanian"
        case .ru: return "Russian"
        case .sk: return "Slovak"
        case .sl: return "Slovenian"
        case .sv: return "Swedish"
        case .ta: return "Tamil"
        case .th: return "Thai"
        case .tl: return "Tagalog"
        case .tr: return "Turkish"
        case .uk: return "Ukrainian"
        case .zh: return "Chinese"
        default:
            return rawValue.isEmpty ? "Unknown" : rawValue
        }
    }
}
