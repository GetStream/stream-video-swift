//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StartTranscriptionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enableClosedCaptions: Bool?
    public var language: String?
    public var transcriptionExternalStorage: String?

    public init(enableClosedCaptions: Bool? = nil, language: String? = nil, transcriptionExternalStorage: String? = nil) {
        self.enableClosedCaptions = enableClosedCaptions
        self.language = language
        self.transcriptionExternalStorage = transcriptionExternalStorage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enableClosedCaptions = "enable_closed_captions"
        case language
        case transcriptionExternalStorage = "transcription_external_storage"
    }
    
    public static func == (lhs: StartTranscriptionRequest, rhs: StartTranscriptionRequest) -> Bool {
        lhs.enableClosedCaptions == rhs.enableClosedCaptions &&
            lhs.language == rhs.language &&
            lhs.transcriptionExternalStorage == rhs.transcriptionExternalStorage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableClosedCaptions)
        hasher.combine(language)
        hasher.combine(transcriptionExternalStorage)
    }
}
