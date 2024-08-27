//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct RecordSettingsResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var audioOnly: Bool
    public var mode: String
    public var quality: String

    public init(audioOnly: Bool, mode: String, quality: String) {
        self.audioOnly = audioOnly
        self.mode = mode
        self.quality = quality
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audioOnly = "audio_only"
        case mode
        case quality
    }
}
