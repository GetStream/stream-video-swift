//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallClosedCaption: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var endTime: Date
    public var speakerId: String
    public var startTime: Date
    public var text: String
    public var user: UserResponse

    public init(endTime: Date, speakerId: String, startTime: Date, text: String, user: UserResponse) {
        self.endTime = endTime
        self.speakerId = speakerId
        self.startTime = startTime
        self.text = text
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case endTime = "end_time"
        case speakerId = "speaker_id"
        case startTime = "start_time"
        case text
        case user
    }
    
    public static func == (lhs: CallClosedCaption, rhs: CallClosedCaption) -> Bool {
        lhs.endTime == rhs.endTime &&
            lhs.speakerId == rhs.speakerId &&
            lhs.startTime == rhs.startTime &&
            lhs.text == rhs.text &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endTime)
        hasher.combine(speakerId)
        hasher.combine(startTime)
        hasher.combine(text)
        hasher.combine(user)
    }
}
