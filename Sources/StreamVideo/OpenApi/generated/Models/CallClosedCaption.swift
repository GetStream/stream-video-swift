//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallClosedCaption represents a closed caption of a call.
public final class CallClosedCaption: @unchecked Sendable, Decodable {
    public var endTime: Date
    public var id: String
    public var language: String
    public var service: String?
    public var speakerId: String
    public var startTime: Date
    public var text: String
    public var translated: Bool
    /// User response object
    public var user: UserResponse

    public init(
        endTime: Date,
        id: String,
        language: String,
        service: String? = nil,
        speakerId: String,
        startTime: Date,
        text: String,
        translated: Bool,
        user: UserResponse
    ) {
        self.endTime = endTime
        self.id = id
        self.language = language
        self.service = service
        self.speakerId = speakerId
        self.startTime = startTime
        self.text = text
        self.translated = translated
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
        self.id = try container.decode(String.self, forKey: .id)
        self.language = try container.decode(String.self, forKey: .language)
        self.service = try container.decodeIfPresent(String.self, forKey: .service)
        self.speakerId = try container.decode(String.self, forKey: .speakerId)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.text = try container.decode(String.self, forKey: .text)
        self.translated = try container.decode(Bool.self, forKey: .translated)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }
}

extension CallClosedCaption: Hashable {
    public static func == (lhs: CallClosedCaption, rhs: CallClosedCaption) -> Bool {
        lhs.endTime == rhs.endTime &&
            lhs.id == rhs.id &&
            lhs.language == rhs.language &&
            lhs.service == rhs.service &&
            lhs.speakerId == rhs.speakerId &&
            lhs.startTime == rhs.startTime &&
            lhs.text == rhs.text &&
            lhs.translated == rhs.translated &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endTime)
        hasher.combine(id)
        hasher.combine(language)
        hasher.combine(service)
        hasher.combine(speakerId)
        hasher.combine(startTime)
        hasher.combine(text)
        hasher.combine(translated)
        hasher.combine(user)
    }
}
