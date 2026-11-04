//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Response for listing recordings
public final class ListRecordingsResponse: @unchecked Sendable, Decodable {
    public var duration: String
    public var recordings: [CallRecording]

    public init(duration: String, recordings: [CallRecording]) {
        self.duration = duration
        self.recordings = recordings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.recordings = try container.decode([CallRecording].self, forKey: .recordings)
    }
}

extension ListRecordingsResponse: Hashable {
    public static func == (lhs: ListRecordingsResponse, rhs: ListRecordingsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.recordings == rhs.recordings
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(recordings)
    }
}
