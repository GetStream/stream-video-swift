//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallRecording represents a recording of a call.
public final class CallRecording: @unchecked Sendable, Codable, JSONEncodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
        self.filename = try container.decode(String.self, forKey: .filename)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.url = try container.decode(String.self, forKey: .url)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(filename, forKey: .filename)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(url, forKey: .url)
    }
}

extension CallRecording: Hashable {
    public static func == (lhs: CallRecording, rhs: CallRecording) -> Bool {
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
