//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallClosedCaption represents a closed caption of a call.
public final class CallClosedCaption: @unchecked Sendable, Codable, JSONEncodable {
    public var endTime: Date
    public var speakerId: String
    public var startTime: Date
    public var text: String
    /// User response object
    public var user: UserResponse

    public init(endTime: Date, speakerId: String, startTime: Date, text: String, user: UserResponse) {
        self.endTime = endTime
        self.speakerId = speakerId
        self.startTime = startTime
        self.text = text
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
        self.speakerId = try container.decode(String.self, forKey: .speakerId)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.text = try container.decode(String.self, forKey: .text)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(speakerId, forKey: .speakerId)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(text, forKey: .text)
        try container.encode(user, forKey: .user)
    }
}

extension CallClosedCaption: Hashable {
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
