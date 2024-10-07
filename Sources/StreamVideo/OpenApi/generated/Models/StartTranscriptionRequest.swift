//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StartTranscriptionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var transcriptionExternalStorage: String?

    public init(transcriptionExternalStorage: String? = nil) {
        self.transcriptionExternalStorage = transcriptionExternalStorage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case transcriptionExternalStorage = "transcription_external_storage"
    }
    
    public static func == (lhs: StartTranscriptionRequest, rhs: StartTranscriptionRequest) -> Bool {
        lhs.transcriptionExternalStorage == rhs.transcriptionExternalStorage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(transcriptionExternalStorage)
    }
}
