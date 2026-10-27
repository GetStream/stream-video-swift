//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StopTranscriptionRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var stopClosedCaptions: Bool?

    public init(stopClosedCaptions: Bool? = nil) {
        self.stopClosedCaptions = stopClosedCaptions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.stopClosedCaptions = try container.decodeIfPresent(Bool.self, forKey: .stopClosedCaptions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(stopClosedCaptions, forKey: .stopClosedCaptions)
    }
}

extension StopTranscriptionRequest: Hashable {
    public static func == (lhs: StopTranscriptionRequest, rhs: StopTranscriptionRequest) -> Bool {
        lhs.stopClosedCaptions == rhs.stopClosedCaptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stopClosedCaptions)
    }
}
