//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ListTranscriptionsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var transcriptions: [CallTranscription]

    public init(duration: String, transcriptions: [CallTranscription]) {
        self.duration = duration
        self.transcriptions = transcriptions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case transcriptions
    }
}
