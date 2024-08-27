//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallClosedCaption: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var endTime: Date
    public var speakerId: String
    public var startTime: Date
    public var text: String

    public init(endTime: Date, speakerId: String, startTime: Date, text: String) {
        self.endTime = endTime
        self.speakerId = speakerId
        self.startTime = startTime
        self.text = text
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case endTime = "end_time"
        case speakerId = "speaker_id"
        case startTime = "start_time"
        case text
    }
}
