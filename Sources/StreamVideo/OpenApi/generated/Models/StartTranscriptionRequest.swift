//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct StartTranscriptionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var transcriptionExternalStorage: String? = nil

    public init(transcriptionExternalStorage: String? = nil) {
        self.transcriptionExternalStorage = transcriptionExternalStorage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case transcriptionExternalStorage = "transcription_external_storage"
    }
}
