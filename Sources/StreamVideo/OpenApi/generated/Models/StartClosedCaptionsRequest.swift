//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StartClosedCaptionsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enableTranscription: Bool?
    public var externalStorage: String?
    public var language: String?

    public init(enableTranscription: Bool? = nil, externalStorage: String? = nil, language: String? = nil) {
        self.enableTranscription = enableTranscription
        self.externalStorage = externalStorage
        self.language = language
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enableTranscription = "enable_transcription"
        case externalStorage = "external_storage"
        case language
    }
    
    public static func == (lhs: StartClosedCaptionsRequest, rhs: StartClosedCaptionsRequest) -> Bool {
        lhs.enableTranscription == rhs.enableTranscription &&
            lhs.externalStorage == rhs.externalStorage &&
            lhs.language == rhs.language
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableTranscription)
        hasher.combine(externalStorage)
        hasher.combine(language)
    }
}
