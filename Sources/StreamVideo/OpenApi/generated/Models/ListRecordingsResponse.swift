//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ListRecordingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var recordings: [CallRecording]

    public init(duration: String, recordings: [CallRecording]) {
        self.duration = duration
        self.recordings = recordings
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case recordings
    }
}
