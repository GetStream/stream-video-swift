//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ListTranscriptionsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var duration: String
    /// List of transcriptions for the call
    public var transcriptions: [CallTranscription]

    public init(duration: String, transcriptions: [CallTranscription]) {
        self.duration = duration
        self.transcriptions = transcriptions
    }

    public enum CodingKeys: String, CodingKey {
        case duration
        case transcriptions
    }
}

extension ListTranscriptionsResponse: Hashable {
    public static func == (lhs: ListTranscriptionsResponse, rhs: ListTranscriptionsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.transcriptions == rhs.transcriptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(transcriptions)
    }
}
