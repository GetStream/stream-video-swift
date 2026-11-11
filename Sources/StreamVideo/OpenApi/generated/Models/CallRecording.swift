//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallRecording represents a recording of a call.
public final class CallRecording: Sendable, Decodable {
    public let endTime: Date
    public let filename: String
    public let recordingType: String
    public let sessionId: String
    public let startTime: Date
    public let url: String

    public init(endTime: Date, filename: String, recordingType: String, sessionId: String, startTime: Date, url: String) {
        self.endTime = endTime
        self.filename = filename
        self.recordingType = recordingType
        self.sessionId = sessionId
        self.startTime = startTime
        self.url = url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
        self.filename = try container.decode(String.self, forKey: .filename)
        self.recordingType = try container.decode(String.self, forKey: .recordingType)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.url = try container.decode(String.self, forKey: .url)
    }
}

extension CallRecording: Hashable {
    public static func == (lhs: CallRecording, rhs: CallRecording) -> Bool {
        lhs.endTime == rhs.endTime &&
            lhs.filename == rhs.filename &&
            lhs.recordingType == rhs.recordingType &&
            lhs.sessionId == rhs.sessionId &&
            lhs.startTime == rhs.startTime &&
            lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endTime)
        hasher.combine(filename)
        hasher.combine(recordingType)
        hasher.combine(sessionId)
        hasher.combine(startTime)
        hasher.combine(url)
    }
}
