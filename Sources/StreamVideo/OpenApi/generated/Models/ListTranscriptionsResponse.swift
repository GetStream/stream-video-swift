//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ListTranscriptionsResponse: @unchecked Sendable, Decodable {
    public var duration: String
    /// List of transcriptions for the call
    public var transcriptions: [CallTranscription]

    public init(duration: String, transcriptions: [CallTranscription]) {
        self.duration = duration
        self.transcriptions = transcriptions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.transcriptions = try container.decode([CallTranscription].self, forKey: .transcriptions)
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
