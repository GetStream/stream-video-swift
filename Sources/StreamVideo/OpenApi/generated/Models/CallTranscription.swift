//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallTranscription: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: CallTranscription, rhs: CallTranscription) -> Bool {
        lhs.endTime == rhs.endTime &&
            lhs.filename == rhs.filename &&
            lhs.startTime == rhs.startTime &&
            lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endTime)
        hasher.combine(filename)
        hasher.combine(startTime)
        hasher.combine(url)
    }
}
