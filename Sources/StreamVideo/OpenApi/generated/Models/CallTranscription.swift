//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallTranscription: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var endTime: Date
    public var filename: String
    public var startTime: Date
    public var url: String

    public init(endTime: Date, filename: String, startTime: Date, url: String) {
        self.endTime = endTime
        self.filename = filename
        self.startTime = startTime
        self.url = url
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case endTime = "end_time"
        case filename
        case startTime = "start_time"
        case url
    }
}
